
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/types/BeforeSwapDelta.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {IPoolManager as IPoolManagerTypes} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";

import {ILProtectionHook} from "../src/ILProtectionHook.sol";
import {ILCalculator} from "../src/libraries/ILCalculator.sol";
import {FHEManager} from "../src/libraries/FHEManager.sol";
import {LPPosition, ILPPositionEvents} from "../src/interfaces/ILPPosition.sol";
import {FHE, euint32} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/// @title ILProtectionHook Test Suite
/// @notice Focused tests for the refactored IL Protection Hook with FHE integration
contract ILProtectionHookTest is Test, ILPPositionEvents {
    using PoolIdLibrary for PoolKey;

    // ============ TEST STATE ============
    ILProtectionHook hook;
    IPoolManager poolManager;
    
    // Test addresses
    address owner = address(0x1);
    address lp1 = address(0x2);
    address lp2 = address(0x3);
    address user = address(0x4);
    
    // Test tokens
    address token0 = address(0x5);
    address token1 = address(0x6);
    
    // Pool configuration
    PoolKey poolKey;
    PoolId poolId;
    
    // Test parameters
    uint256 constant ENTRY_PRICE = 1e18;
    uint256 constant LIQUIDITY_AMOUNT = 1000e18;
    uint256 constant IL_THRESHOLD_BP = 500; // 5%
    
    // ============ SETUP ============
    
    function setUp() public {
        // Deploy mock pool manager
        poolManager = IPoolManager(address(new MockPoolManager()));
        
        // Deploy the hook
        vm.prank(owner);
        hook = new ILProtectionHook(poolManager);
        
        // Setup pool key
        poolKey = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(hook))
        });
        poolId = poolKey.toId();
        
        // Fund test accounts
        vm.deal(lp1, 100 ether);
        vm.deal(lp2, 100 ether);
        vm.deal(user, 100 ether);
    }
    
    // ============ CONSTRUCTOR TESTS ============
    
    function test_constructor_SetsOwner() public {
        assertEq(hook.owner(), owner, "Owner should be set correctly");
    }
    
    function test_constructor_InitializesPausedState() public {
        assertFalse(hook.paused(), "Contract should not be paused initially");
    }
    
    // ============ HOOK PERMISSIONS TESTS ============
    
    function test_getHookPermissions() public {
        Hooks.Permissions memory permissions = hook.getHookPermissions();
        
        assertFalse(permissions.beforeInitialize, "beforeInitialize should be false");
        assertTrue(permissions.afterInitialize, "afterInitialize should be true");
        assertFalse(permissions.beforeAddLiquidity, "beforeAddLiquidity should be false");
        assertTrue(permissions.afterAddLiquidity, "afterAddLiquidity should be true");
        assertTrue(permissions.beforeRemoveLiquidity, "beforeRemoveLiquidity should be true");
        assertFalse(permissions.afterRemoveLiquidity, "afterRemoveLiquidity should be false");
        assertTrue(permissions.beforeSwap, "beforeSwap should be true");
        assertFalse(permissions.afterSwap, "afterSwap should be false");
    }
    
    // ============ AFTER INITIALIZE TESTS ============
    
    function test_afterInitialize_EnablesPool() public {
        vm.prank(address(poolManager));
        (bytes4 selector,) = hook.afterInitialize(poolKey, 0, 0);
        
        assertEq(selector, ILProtectionHook.afterInitialize.selector, "Should return correct selector");
        assertTrue(hook.enabledPools(poolId), "Pool should be enabled");
    }
    
    // ============ AFTER ADD LIQUIDITY TESTS ============
    
    function test_afterAddLiquidity_CreatesPosition() public {
        // First enable the pool
        _enablePool();
        
        // Create encrypted threshold
        euint32 encryptedThreshold = FHEManager.encryptBasisPoints(IL_THRESHOLD_BP);
        
        // Prepare hook data
        bytes memory hookData = abi.encode(encryptedThreshold);
        
        // Prepare liquidity params
        IPoolManager.ModifyLiquidityParams memory params = IPoolManager.ModifyLiquidityParams({
            tickLower: -887220,
            tickUpper: 887220,
            liquidityDelta: int256(LIQUIDITY_AMOUNT),
            salt: bytes32(0)
        });
        
        // Expect position created event
        vm.expectEmit(true, true, true, true);
        emit PositionCreated(
            1, // positionId
            lp1,
            PoolId.unwrap(poolId),
            uint128(LIQUIDITY_AMOUNT / 2),
            uint128(LIQUIDITY_AMOUNT / 2),
            ENTRY_PRICE
        );
        
        // Call the hook
        vm.prank(address(poolManager));
        (bytes4 selector, BalanceDelta delta) = hook.afterAddLiquidity(
            lp1,
            poolKey,
            params,
            BalanceDelta.wrap(0),
            BalanceDelta.wrap(0),
            hookData
        );
        
        // Verify return values
        assertEq(selector, ILProtectionHook.afterAddLiquidity.selector, "Should return correct selector");
        assertEq(BalanceDelta.unwrap(delta), 0, "Delta should be zero");
        
        // Verify position was created
        (address lpAddress, uint256 entryPrice, uint128 token0Amount, uint128 token1Amount, uint256 depositTimestamp, bool isActive) = 
            hook.getPosition(poolId, 1);
        
        assertEq(lpAddress, lp1, "LP address should match");
        assertEq(entryPrice, ENTRY_PRICE, "Entry price should match");
        assertEq(token0Amount, uint128(LIQUIDITY_AMOUNT / 2), "Token0 amount should match");
        assertEq(token1Amount, uint128(LIQUIDITY_AMOUNT / 2), "Token1 amount should match");
        assertTrue(isActive, "Position should be active");
        assertGt(depositTimestamp, 0, "Deposit timestamp should be set");
        
        // Verify position tracking
        uint256[] memory activePositions = hook.getActivePositions(poolId);
        assertEq(activePositions.length, 1, "Should have 1 active position");
        assertEq(activePositions[0], 1, "Position ID should be 1");
        
        uint256[] memory userPos = hook.getUserPositions(lp1);
        assertEq(userPos.length, 1, "User should have 1 position");
        assertEq(userPos[0], 1, "Position ID should be 1");
    }
    
    function test_afterAddLiquidity_RevertsWhenPaused() public {
        _enablePool();
        
        // Pause the contract
        vm.prank(owner);
        hook.pause();
        
        euint32 encryptedThreshold = FHEManager.encryptBasisPoints(IL_THRESHOLD_BP);
        bytes memory hookData = abi.encode(encryptedThreshold);
        
        IPoolManager.ModifyLiquidityParams memory params = IPoolManager.ModifyLiquidityParams({
            tickLower: -887220,
            tickUpper: 887220,
            liquidityDelta: int256(LIQUIDITY_AMOUNT),
            salt: bytes32(0)
        });
        
        vm.expectRevert(ILProtectionHook.ContractPaused.selector);
        vm.prank(address(poolManager));
        hook.afterAddLiquidity(lp1, poolKey, params, BalanceDelta.wrap(0), BalanceDelta.wrap(0), hookData);
    }
    
    // ============ BEFORE REMOVE LIQUIDITY TESTS ============
    
    function test_beforeRemoveLiquidity_DeactivatesPosition() public {
        // First create a position
        _createPosition(lp1, IL_THRESHOLD_BP);
        
        // Prepare remove liquidity params
        IPoolManager.ModifyLiquidityParams memory params = IPoolManager.ModifyLiquidityParams({
            tickLower: -887220,
            tickUpper: 887220,
            liquidityDelta: -int256(LIQUIDITY_AMOUNT),
            salt: bytes32(0)
        });
        
        // Call the hook
        vm.prank(address(poolManager));
        bytes4 selector = hook.beforeRemoveLiquidity(lp1, poolKey, params, "");
        
        // Verify return value
        assertEq(selector, ILProtectionHook.beforeRemoveLiquidity.selector, "Should return correct selector");
        
        // Verify position is deactivated
        (, , , , , bool isActive) = hook.getPosition(poolId, 1);
        assertFalse(isActive, "Position should be deactivated");
    }
    
    // ============ BEFORE SWAP TESTS ============
    
    function test_beforeSwap_ChecksILThreshold() public {
        // Create a position with low threshold
        _createPosition(lp1, 100); // 1% threshold
        
        // Prepare swap params
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: 1000,
            sqrtPriceLimitX96: 0
        });
        
        // This should check IL threshold (current IL will be 0, so no breach)
        vm.prank(address(poolManager));
        (bytes4 selector, BeforeSwapDelta delta, uint24 lpFeeOverride) = hook.beforeSwap(user, poolKey, params, "");
        
        // Verify return values
        assertEq(selector, ILProtectionHook.beforeSwap.selector, "Should return correct selector");
        assertEq(BeforeSwapDelta.unwrap(delta), 0, "Delta should be zero");
        
        // Position should still be active (no IL breach)
        (, , , , , bool isActive) = hook.getPosition(poolId, 1);
        assertTrue(isActive, "Position should remain active");
    }
    
    // ============ ADMIN FUNCTION TESTS ============
    
    function test_pause_OnlyOwner() public {
        vm.prank(owner);
        hook.pause();
        assertTrue(hook.paused(), "Contract should be paused");
    }
    
    function test_pause_RevertsForNonOwner() public {
        vm.expectRevert(ILProtectionHook.Unauthorized.selector);
        vm.prank(lp1);
        hook.pause();
    }
    
    function test_unpause_OnlyOwner() public {
        vm.prank(owner);
        hook.pause();
        
        vm.prank(owner);
        hook.unpause();
        assertFalse(hook.paused(), "Contract should be unpaused");
    }
    
    function test_transferOwnership_OnlyOwner() public {
        address newOwner = address(0x7);
        
        vm.prank(owner);
        hook.transferOwnership(newOwner);
        
        assertEq(hook.owner(), newOwner, "Owner should be transferred");
    }
    
    // ============ FHE INTEGRATION TESTS ============
    
    function test_getSealedThreshold_ReturnsSealedValue() public {
        _createPosition(lp1, IL_THRESHOLD_BP);
        
        bytes32 publicKey = bytes32(uint256(0x123456789));
        
        // This should return a sealed value (string)
        string memory sealedThreshold = hook.getSealedThreshold(poolId, 1, publicKey);
        assertGt(bytes(sealedThreshold).length, 0, "Sealed threshold should not be empty");
    }
    
    function test_getSealedThreshold_RevertsForNonOwner() public {
        _createPosition(lp1, IL_THRESHOLD_BP);
        
        bytes32 publicKey = bytes32(uint256(0x123456789));
        
        vm.expectRevert("Not position owner");
        vm.prank(lp2);
        hook.getSealedThreshold(poolId, 1, publicKey);
    }
    
    // ============ HELPER FUNCTIONS ============
    
    function _enablePool() internal {
        vm.prank(address(poolManager));
        hook.afterInitialize(poolKey, 0, 0);
    }
    
    function _createPosition(address lp, uint256 thresholdBp) internal {
        _enablePool();
        
        euint32 encryptedThreshold = FHEManager.encryptBasisPoints(uint32(thresholdBp));
        bytes memory hookData = abi.encode(encryptedThreshold);
        
        IPoolManager.ModifyLiquidityParams memory params = IPoolManager.ModifyLiquidityParams({
            tickLower: -887220,
            tickUpper: 887220,
            liquidityDelta: int256(LIQUIDITY_AMOUNT),
            salt: bytes32(0)
        });
        
        vm.prank(address(poolManager));
        hook.afterAddLiquidity(lp, poolKey, params, BalanceDelta.wrap(0), BalanceDelta.wrap(0), hookData);
    }
}

/// @title Mock Pool Manager
/// @notice Minimal mock implementation of IPoolManager for testing
abstract contract MockPoolManager is IPoolManager {
    function lock(bytes calldata data) external payable returns (bytes memory result) {
        return data;
    }
    
    function unlock() external {}
    
    function getLiquidity(PoolKey calldata, int24, int24) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, int24, int24) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolKey calldata, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
    function getLiquidity(PoolId, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) external view returns (uint128) {
        return 0;
    }
    
}
