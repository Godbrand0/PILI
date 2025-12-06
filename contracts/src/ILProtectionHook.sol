// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// ============ IMPORTS (Match v4-template pattern EXACTLY) ============
import {BaseHook} from "v4-periphery/utils/BaseHook.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/types/BeforeSwapDelta.sol";
import {ModifyLiquidityParams, SwapParams} from "v4-core/types/PoolOperation.sol";

// Import your libraries
import {ILCalculator} from "./libraries/ILCalculator.sol";
import {FHEManager} from "./libraries/FHEManager.sol";
import {LPPosition, ILPPositionEvents, euint32} from "./interfaces/ILPPosition.sol";

/// @title IL Protection Hook
/// @notice Provides Impermanent Loss protection for Uniswap v4 LPs using FHE
/// @dev Follows official v4-template BaseHook pattern with internal _functions
contract ILProtectionHook is BaseHook, ILPPositionEvents {
    using PoolIdLibrary for PoolKey;

    // ============ STATE VARIABLES ============
    mapping(PoolId => mapping(uint256 => LPPosition)) public positions;
    mapping(PoolId => uint256[]) public activePositionIds;
    mapping(address => uint256[]) public userPositions;
    mapping(PoolId => bool) public enabledPools;
    
    uint256 public nextPositionId = 1;
    uint256 public totalProtectedLiquidity;
    bool public paused;
    address public owner;
    
    // ============ EVENTS ============
    event PoolEnabled(PoolId indexed poolId);
    event ProtectionTriggered(uint256 indexed positionId, uint256 ilAmount);

    // ============ ERRORS ============
    error ContractPaused();
    error Unauthorized();

    // ============ MODIFIERS ============
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    // ============ CONSTRUCTOR ============
    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {
        owner = msg.sender;
    }

    // ============ HOOK PERMISSIONS ============
    function getHookPermissions() 
        public 
        pure 
        override 
        returns (Hooks.Permissions memory) 
    {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: true,
            beforeAddLiquidity: false,
            afterAddLiquidity: true,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // ============ INTERNAL HOOK IMPLEMENTATIONS ============

    function _afterInitialize(address, PoolKey calldata key, uint160, int24) 
        internal 
        override 
        returns (bytes4) 
    {
        PoolId poolId = key.toId();
        enabledPools[poolId] = true;
        emit PoolEnabled(poolId);
        return BaseHook.afterInitialize.selector;
    }

    function _afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta,
        BalanceDelta,
        bytes calldata hookData
    ) internal override returns (bytes4, BalanceDelta) {
        if (paused) revert ContractPaused();
        
        PoolId poolId = key.toId();
        
        if (hookData.length > 0 && enabledPools[poolId]) {
            euint32 encryptedThreshold = abi.decode(hookData, (euint32));
            
            uint256 positionId = nextPositionId++;
            
            positions[poolId][positionId] = LPPosition({
                lpAddress: sender,
                isActive: true,
                positionId: uint96(positionId),
                entryPrice: 1e18,
                token0Amount: uint128(uint256(params.liquidityDelta) / 2),
                token1Amount: uint128(uint256(params.liquidityDelta) / 2),
                encryptedILThreshold: encryptedThreshold,
                depositTimestamp: block.timestamp
            });

            activePositionIds[poolId].push(positionId);
            userPositions[sender].push(positionId);
            totalProtectedLiquidity += uint256(params.liquidityDelta);

            emit PositionCreated(
                positionId,
                sender,
                PoolId.unwrap(poolId),
                positions[poolId][positionId].token0Amount,
                positions[poolId][positionId].token1Amount,
                1e18
            );
        }

        return (BaseHook.afterAddLiquidity.selector, BalanceDelta.wrap(0));
    }

    function _beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata,
        bytes calldata
    ) internal override returns (bytes4) {
        if (paused) revert ContractPaused();

        PoolId poolId = key.toId();
        uint256[] memory activeIds = activePositionIds[poolId];
        
        for (uint256 i = 0; i < activeIds.length; i++) {
            LPPosition storage position = positions[poolId][activeIds[i]];
            if (position.lpAddress == sender && position.isActive) {
                uint256 currentIL = ILCalculator.calculateIL(position.entryPrice, 1e18);
                bool exceedsThreshold = FHEManager.compareThresholds(currentIL, position.encryptedILThreshold);
                
                if (exceedsThreshold) {
                    emit ILThresholdBreached(activeIds[i], PoolId.unwrap(poolId), currentIL);
                }
                
                position.isActive = false;
                totalProtectedLiquidity -= position.token0Amount + position.token1Amount;
                break;
            }
        }

        return BaseHook.beforeRemoveLiquidity.selector;
    }

    function _beforeSwap(address, PoolKey calldata key, SwapParams calldata, bytes calldata)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        if (paused) revert ContractPaused();

        PoolId poolId = key.toId();
        uint256[] memory activeIds = activePositionIds[poolId];
        
        for (uint256 i = 0; i < activeIds.length && i < 50; i++) {
            LPPosition storage position = positions[poolId][activeIds[i]];
            if (!position.isActive) continue;

            uint256 currentIL = ILCalculator.calculateIL(position.entryPrice, 1e18);
            bool shouldExit = FHEManager.compareThresholds(currentIL, position.encryptedILThreshold);

            if (shouldExit) {
                position.isActive = false;
                emit ILThresholdBreached(activeIds[i], PoolId.unwrap(poolId), currentIL);
                emit ProtectionTriggered(activeIds[i], currentIL);
            }
        }

        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    // ============ VIEW FUNCTIONS ============
    
    function getPosition(PoolId poolId, uint256 positionId)
        external
        view
        returns (
            address lpAddress,
            uint256 entryPrice,
            uint128 token0Amount,
            uint128 token1Amount,
            uint256 depositTimestamp,
            bool isActive
        )
    {
        LPPosition storage pos = positions[poolId][positionId];
        return (pos.lpAddress, pos.entryPrice, pos.token0Amount, pos.token1Amount, pos.depositTimestamp, pos.isActive);
    }

    function getActivePositions(PoolId poolId) external view returns (uint256[] memory) {
        return activePositionIds[poolId];
    }

    function getUserPositions(address user) external view returns (uint256[] memory) {
        return userPositions[user];
    }

    // ============ ADMIN FUNCTIONS ============

    function pause() external onlyOwner {
        paused = true;
        emit EmergencyPauseChanged(true, msg.sender);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit EmergencyPauseChanged(false, msg.sender);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert Unauthorized();
        owner = newOwner;
    }
}
