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
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";

// Import FHE library with CORRECT path
import {FHE, euint32, ebool} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

// Import your libraries
import {ILCalculator} from "./libraries/ILCalculator.sol";
import {FHEManager} from "./FHEManager.sol";
import {LPPosition, ILPPositionEvents} from "./interfaces/ILPPosition.sol";

/// @title IL Protection Hook (FHE-Refactored)
/// @notice Provides Impermanent Loss protection for Uniswap v4 LPs using FHE
/// @dev Follows Fhenix FHE best practices with proper access control
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
    
    // FHE Manager contract instance
    FHEManager public fheVerifier;

    // ✅ FHE CONSTANTS (Gas Optimization)
    euint32 private ENCRYPTED_ZERO;
    euint32 private ENCRYPTED_MAX_BP; // 10000 basis points = 100%

    // ============ EVENTS ============
    event PoolEnabled(PoolId indexed poolId);
    event ProtectionTriggered(uint256 indexed positionId, uint256 ilAmount);

    // ============ ERRORS ============
    error ContractPaused();
    error Unauthorized();
    error InvalidEncryptedThreshold();

    // ============ MODIFIERS ============
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    // ============ CONSTRUCTOR ============
    // ============ CONSTRUCTOR ============
    constructor(IPoolManager _poolManager, address _fheManager) BaseHook(_poolManager) {
        owner = msg.sender;
        
        // Use provided FHE Manager or deploy new one
        if (_fheManager != address(0)) {
            fheVerifier = FHEManager(_fheManager);
        } else {
            fheVerifier = new FHEManager();
        }

        // ✅ Initialize encrypted constants via FHEManager
        // This avoids direct FHE precompile calls in this contract, enabling testing
        ENCRYPTED_ZERO = fheVerifier.getEncryptedZeroFor(address(this));
        ENCRYPTED_MAX_BP = fheVerifier.getEncryptedMaxBpFor(address(this));
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

    function _afterInitialize(address, PoolKey calldata key, uint160 sqrtPriceX96, int24)
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
        IPoolManager.ModifyLiquidityParams calldata params,
        BalanceDelta,
        BalanceDelta,
        bytes calldata hookData
    ) internal override returns (bytes4, BalanceDelta) {
        if (paused) revert ContractPaused();

        PoolId poolId = key.toId();

        if (hookData.length > 0 && enabledPools[poolId]) {
            euint32 encryptedThreshold = abi.decode(hookData, (euint32));

            // ✅ CRITICAL FIX #1: Validate encrypted value
            // Note: FHE.isInitialized() doesn't exist in current FHE library
            // We'll check if the value is 0 (uninitialized) instead
            if (euint32.unwrap(encryptedThreshold) == 0) {
                revert InvalidEncryptedThreshold();
            }

            uint256 positionId = nextPositionId++;

            // ✅ CRITICAL FIX #2: Grant access BEFORE storing
            // Contract needs access to use this value in future hooks
            // LP needs access to retrieve via getSealedThreshold()
            fheVerifier.grantAccess(encryptedThreshold, sender);

            // Get current sqrtPriceX96 from pool state
            (uint160 currentSqrtPriceX96,,,) = StateLibrary.getSlot0(poolManager, poolId);

            // NOW store the position with proper permissions
            positions[poolId][positionId] = LPPosition({
                lpAddress: sender,
                isActive: true,
                positionId: uint96(positionId),
                entryPrice: uint256(currentSqrtPriceX96),
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
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) internal override returns (bytes4) {
        if (paused) revert ContractPaused();

        PoolId poolId = key.toId();
        uint256[] memory activeIds = activePositionIds[poolId];

        for (uint256 i = 0; i < activeIds.length; i++) {
            LPPosition storage position = positions[poolId][activeIds[i]];
            if (position.lpAddress == sender && position.isActive) {
                // Get current sqrtPriceX96 from pool state
                (uint160 currentSqrtPriceX96,,,) = StateLibrary.getSlot0(poolManager, poolId);
                
                uint256 currentIL = ILCalculator.calculateIL(position.entryPrice, uint256(currentSqrtPriceX96));

                // ✅ CRITICAL FIX #4: Use external FHEManager contract
                // This now uses try/catch with external call pattern
                try fheVerifier.requireThresholdBreached(currentIL, position.encryptedILThreshold) {
                    // Threshold breached, emit event
                    emit ILThresholdBreached(activeIds[i], PoolId.unwrap(poolId), currentIL);
                } catch {
                    // Threshold not breached, continue normally
                }

                position.isActive = false;
                totalProtectedLiquidity -= position.token0Amount + position.token1Amount;
                break;
            }
        }

        return BaseHook.beforeRemoveLiquidity.selector;
    }

    function _beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata, bytes calldata)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        if (paused) revert ContractPaused();

        PoolId poolId = key.toId();
        uint256[] memory activeIds = activePositionIds[poolId];

        // Check up to 50 positions per swap (gas limit protection)
        for (uint256 i = 0; i < activeIds.length && i < 50; i++) {
            LPPosition storage position = positions[poolId][activeIds[i]];
            if (!position.isActive) continue;

            // Get current sqrtPriceX96 from pool state
            (uint160 currentSqrtPriceX96,,,) = StateLibrary.getSlot0(poolManager, poolId);
            
            uint256 currentIL = ILCalculator.calculateIL(position.entryPrice, uint256(currentSqrtPriceX96));

            // ✅ CRITICAL FIX #5: Use try/catch with external FHEManager
            // If threshold breached, call succeeds and we exit position
            // If threshold NOT breached, call reverts and we catch it
            try fheVerifier.requireThresholdBreached(currentIL, position.encryptedILThreshold) {
                // Threshold breached - trigger protection
                position.isActive = false;
                emit ILThresholdBreached(activeIds[i], PoolId.unwrap(poolId), currentIL);
                emit ProtectionTriggered(activeIds[i], currentIL);
            } catch {
                // Threshold not breached - continue normally
                // This is the expected case most of the time
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

    // ✅ NEW FUNCTION: Allow LPs to retrieve their encrypted threshold
    /// @notice Get encrypted threshold for LP to decrypt client-side with cofhejs
    /// @param poolId Pool identifier
    /// @param positionId Position identifier
    /// @return Encrypted threshold that only LP can decrypt
    function getSealedThreshold(
        PoolId poolId,
        uint256 positionId
    ) external view returns (euint32) {
        LPPosition storage pos = positions[poolId][positionId];
        require(pos.lpAddress == msg.sender, "Not position owner");

        // Return the encrypted threshold directly
        // The user will decrypt it using cofhejs on the client side
        // Access control was granted via FHE.allowSender in afterAddLiquidity
        return pos.encryptedILThreshold;
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
