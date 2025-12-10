# PILI Smart Contract Deployment Guide

This guide covers deploying the PILI smart contracts for privacy-preserving impermanent loss protection on Uniswap v4.

## Prerequisites

1. **Foundry Installed**

   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Fhenix Testnet ETH**

   - Get testnet ETH from [Fhenix Faucet](https://faucet.fhenix.zone/)
   - Ensure you have at least 0.1 ETH for deployment

3. **Uniswap v4 Components**
   - PoolManager deployed on Fhenix
   - Required v4-core contracts available

## Contract Overview

### 1. ILProtectionHook.sol

The main hook contract that provides IL protection for Uniswap v4 pools.

**Constructor Parameters:**

- `_poolManager` (address): The Uniswap v4 PoolManager contract address

**Key Features:**

- Hooks into liquidity addition, removal, and swaps
- Stores encrypted IL thresholds
- Automatically exits positions when IL exceeds threshold
- Emits events for position tracking

### 2. FHEManager.sol (Library)

A library providing FHE operations for privacy-preserving comparisons.

**Key Functions:**

- `encryptBasisPoints()`: Encrypt IL thresholds
- `compareThresholds()`: Compare IL against encrypted thresholds
- `validateEncryptedThreshold()`: Validate encrypted values

### 3. ILCalculator.sol (Library)

Calculates impermanent loss based on price changes.

**Key Functions:**

- `calculateIL()`: Calculate IL percentage
- `calculatePriceRatio()`: Calculate price change ratio

## Deployment Steps

### 1. Setup Environment

Create a `.env` file in the contracts directory:

```env
# Fhenix Testnet
FHENIX_RPC_URL=https://helix.fhenix.zone
FHENIX_CHAIN_ID=8008

# Uniswap v4 PoolManager (get from Fhenix deployment)
POOL_MANAGER_ADDRESS=0x...

# Deployer Private Key (NEVER commit this)
PRIVATE_KEY=your_private_key_here

# Etherscan (for verification)
ETHERSCAN_API_KEY=your_api_key_here
```

### 2. Deploy ILProtectionHook

```bash
# Navigate to contracts directory
cd contracts

# Compile contracts
forge build

# Deploy ILProtectionHook
forge create \
  --rpc-url $FHENIX_RPC_URL \
  --private-key $PRIVATE_KEY \
  --constructor-args $POOL_MANAGER_ADDRESS \
  src/ILProtectionHook.sol:ILProtectionHook \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

**Example Output:**

```
Deployer: 0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b
Deployed to: 0x1234567890123456789012345678901234567890
Transaction hash: 0x...
Gas used: 3456789
```

### 3. Verify Deployment

```bash
# Verify contract is deployed and working
cast call \
  --rpc-url $FHENIX_RPC_URL \
  $DEPLOYED_ADDRESS \
  "owner()(address)"
```

### 4. Configure Hook for Pool

After deployment, you need to register the hook with a Uniswap v4 pool:

```bash
# This would be done through PoolManager's setHook function
# (Implementation depends on v4-core version)
```

## Constructor Details

### ILProtectionHook Constructor

```solidity
constructor(IPoolManager _poolManager) BaseHook(_poolManager) {
    owner = msg.sender;
}
```

**Parameters:**

- `_poolManager`: Address of the deployed Uniswap v4 PoolManager contract

**What it does:**

1. Initializes the BaseHook with PoolManager
2. Sets the deployer as the owner
3. Initializes state variables to defaults

## Post-Deployment Configuration

### 1. Enable Pool Protection

```solidity
// This is called automatically when a pool is initialized with the hook
// Or manually enable specific pools:

function enablePool(PoolId poolId) external onlyOwner {
    enabledPools[poolId] = true;
    emit PoolEnabled(poolId);
}
```

### 2. Set Owner (Optional)

If you need to transfer ownership:

```solidity
function transferOwnership(address newOwner) external onlyOwner {
    if (newOwner == address(0)) revert Unauthorized();
    owner = newOwner;
}
```

### 3. Emergency Controls

```solidity
// Pause all protection (emergency)
function pause() external onlyOwner {
    paused = true;
    emit EmergencyPauseChanged(true, msg.sender);
}

// Unpause
function unpause() external onlyOwner {
    paused = false;
    emit EmergencyPauseChanged(false, msg.sender);
}
```

## Gas Estimates

| Operation                     | Gas Cost | Notes                     |
| ----------------------------- | -------- | ------------------------- |
| Deployment                    | ~3.5M    | Includes library linking  |
| Add Liquidity with Protection | ~200k    | + FHE encryption cost     |
| IL Check (per position)       | ~150k    | FHE comparison operations |
| Emergency Exit                | ~100k    | Simple state change       |

## Testing Deployment

### 1. Unit Tests

```bash
# Run all tests
forge test

# Run specific test
forge test --match-test testAddLiquidityWithProtection

# Run with gas report
forge test --gas-report
```

### 2. Integration Tests

```bash
# Deploy to testnet first
forge script script/Deploy.s.sol --rpc-url $FHENIX_RPC_URL --broadcast

# Verify functionality
forge script script/TestDeployment.s.sol --rpc-url $FHENIX_RPC_URL --broadcast
```

### 3. FHE Testing

Test FHE operations specifically:

```bash
# Test FHE encryption/decryption
forge test --match-test testFHEOperations

# Test threshold comparison
forge test --match-test testThresholdComparison
```

## Frontend Integration

Update your frontend configuration with deployed addresses:

```typescript
// config/contracts.ts
export const IL_PROTECTION_HOOK_ADDRESS = "0x..."; // Deployed address
export const POOL_MANAGER_ADDRESS = "0x..."; // v4 PoolManager
export const FHENIX_CHAIN_ID = 8008;
```

## Security Considerations

### 1. Contract Security

- ✅ Owner-only functions protected
- ✅ Reentrancy protection via BaseHook
- ✅ Input validation for FHE values
- ✅ Emergency pause functionality

### 2. FHE Security

- ✅ Encrypted thresholds never decrypted publicly
- ✅ Only boolean comparison results exposed
- ✅ Proper FHE library usage
- ✅ No plaintext threshold storage

### 3. Operational Security

- ✅ Multi-signature for critical operations (recommended)
- ✅ Time delays for ownership transfer
- ✅ Monitoring for unusual activity

## Monitoring

### 1. Events to Monitor

```solidity
// Key events for off-chain monitoring
event PositionCreated(uint256 indexed positionId, address indexed lpAddress, ...);
event ILThresholdBreached(uint256 indexed positionId, uint256 ilAmount);
event ProtectionTriggered(uint256 indexed positionId, uint256 ilAmount);
event EmergencyPauseChanged(bool paused, address indexed caller);
```

### 2. Metrics to Track

- Total protected liquidity
- Number of active positions
- IL threshold breach frequency
- Gas usage per operation
- FHE operation success rate

## Troubleshooting

### Common Issues

1. **FHE Operations Fail**

   - Ensure Fhenix testnet is active
   - Check FHE library version compatibility
   - Verify sufficient gas for FHE operations

2. **Hook Not Triggered**

   - Verify hook is registered with PoolManager
   - Check pool is enabled in the contract
   - Ensure correct hook permissions

3. **Gas Too High**
   - Optimize position checking loop
   - Consider batch operations
   - Use FHE caching for repeated operations

### Debug Commands

```bash
# Check contract state
cast call --rpc-url $FHENIX_RPC_URL $CONTRACT_ADDRESS "paused()(bool)"

# Check specific position
cast call --rpc-url $FHENIX_RPC_URL $CONTRACT_ADDRESS "getPosition(bytes32,uint256)(address,uint256,uint128,uint128,uint256,bool)" $POOL_ID $POSITION_ID

# Get active positions
cast call --rpc-url $FHENIX_RPC_URL $CONTRACT_ADDRESS "getActivePositions(bytes32)(uint256[])" $POOL_ID
```

## Production Checklist

- [ ] Deploy to Fhenix mainnet
- [ ] Verify all contracts on Etherscan
- [ ] Set up monitoring and alerts
- [ ] Configure multi-sig for owner
- [ ] Test with real liquidity
- [ ] Document all addresses
- [ ] Set up emergency procedures
- [ ] Conduct security audit
- [ ] Create upgrade path

## Upgrade Path

The contract is designed to be upgradeable through:

1. **Proxy Pattern**: Can be deployed behind a proxy
2. **Hook Replacement**: New hook can be registered
3. **Library Updates**: FHE libraries can be upgraded

Always test upgrades on testnet first!
