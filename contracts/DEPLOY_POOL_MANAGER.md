# Deploy PoolManager and ILProtectionHook on Fhenix Testnet

This guide will help you deploy both the Uniswap v4 PoolManager and the ILProtectionHook_REFACTORED contract on Fhenix testnet.

## Prerequisites

1. **Get Fhenix Testnet ETH**
   - Visit [Fhenix Faucet](https://faucet.fhenix.zone/) to get testnet ETH
   - Ensure you have at least 0.1 ETH for deployment

2. **Set up Environment**
   ```bash
   # Copy the example environment file
   cp .env.example .env
   
   # Edit .env with your actual private key
   nano .env
   ```

## Fixed Configuration

The `foundry.toml` file has been fixed to resolve the TOML syntax error. You should now be able to run Foundry commands without issues.

## Deployment Steps

### Option 1: Deploy Both Contracts Together (Recommended)

Use the custom deployment script that deploys both contracts in sequence:

```bash
cd contracts

# Deploy both PoolManager and ILProtectionHook
forge script script/DeployPiliSystem.s.sol:DeployPiliSystem \
  --rpc-url https://helix.fhenix.zone \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

### Option 2: Deploy PoolManager Only

If you only want to deploy the PoolManager:

```bash
cd contracts

# Deploy PoolManager using the v4-periphery script
forge script script/01_PoolManager.s.sol:DeployPoolManager \
  --rpc-url https://helix.fhenix.zone \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --no-fork
```

### Option 3: Deploy Using forge create

If the script approach doesn't work, you can deploy directly:

```bash
cd contracts

# Deploy PoolManager
forge create \
  --rpc-url https://helix.fhenix.zone \
  --private-key $PRIVATE_KEY \
  --constructor-args $(cast address $(cast wallet address)) \
  src/PoolManager.sol:PoolManager \
  --verify
```

## After Deployment

1. **Save Contract Addresses**
   
   The deployment script will output the contract addresses. Save them to your `.env` file:
   ```env
   POOL_MANAGER_ADDRESS=0x... # PoolManager address from deployment
   IL_PROTECTION_HOOK_ADDRESS=0x... # ILProtectionHook address from deployment
   ```

2. **Update Frontend Configuration**
   
   Update your frontend configuration with the deployed addresses:
   ```typescript
   // frontend/config/contracts.ts
   export const POOL_MANAGER_ADDRESS = "0x..."; // Your deployed PoolManager
   export const IL_PROTECTION_HOOK_ADDRESS = "0x..."; // Your deployed hook
   export const FHENIX_CHAIN_ID = 8008;
   ```

## Troubleshooting

### Error: "failed to extract foundry config"
This was caused by a syntax error in `foundry.toml` which has been fixed.

### Error: "a value is required for '--fork-url'"
Add the `--no-fork` flag to your deployment command to prevent Foundry from expecting a fork URL.

### Error: "insufficient funds"
Make sure you have enough testnet ETH in your wallet. You can get more from the [Fhenix Faucet](https://faucet.fhenix.zone/).

## Verification

After deployment, you can verify your contracts on the Fhenix block explorer:
- [Fhenix Explorer](https://fhenix-explorer.alphabeta.com/)

## Next Steps

1. Test your deployed contracts on Fhenix testnet
2. Create a pool with your ILProtectionHook
3. Add liquidity with an encrypted IL threshold
4. Test the impermanent loss protection functionality

## Security Notes

- Never commit your private key to version control
- Use a dedicated deployer wallet for testnet deployments
- Verify contract addresses before interacting with them
- Test thoroughly before deploying to mainnet