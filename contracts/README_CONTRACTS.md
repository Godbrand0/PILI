# PILI Smart Contracts Documentation

## Overview

PILI (Private Impermanent Loss Insurance) is a DeFi protocol that provides privacy-preserving impermanent loss protection for liquidity providers in Uniswap v4 pools. The system uses Fully Homomorphic Encryption (FHE) to keep user positions and thresholds private while still allowing the protocol to automatically trigger protection when impermanent loss exceeds predefined thresholds.

## Architecture

The PILI system consists of several key components:

1. **ILProtectionHook** - A Uniswap v4 hook that monitors pool positions and triggers IL protection
2. **ILCalculator** - Library for calculating impermanent loss from price changes
3. **FHEManager** - Interface to the FHE system for encrypted operations
4. **PositionManager** - Manages LP positions and their protection parameters

## Contract Structure

```
contracts/
├── src/
│   ├── ILProtectionHook.sol          # Main hook contract
│   ├── ILProtectionHook_REFACTORED.sol # Refactored version
│   ├── FHEManager.sol                 # FHE operations interface
│   └── libraries/
│       └── ILCalculator.sol          # IL calculation library with sqrtPriceX96 support
├── script/
│   ├── DeployPiliSystem.s.sol        # Deployment script
│   └── Deploy.s.sol                   # Alternative deployment
├── test/
│   ├── ILProtectionHookTest.sol      # Hook tests
│   ├── ILCalculationTest.sol         # IL calculation tests
│   ├── ILCalculatorDebugTest.sol     # Debug tests
│   └── mocks/
│       └── MockFHEManager.sol        # Mock FHE for testing
└── lib/                              # External dependencies
    ├── v4-core/                       # Uniswap v4 core
    ├── v4-periphery/                  # Uniswap v4 periphery
    ├── forge-std/                     # Foundry standard library
    └── openzeppelin-contracts/        # OpenZeppelin contracts
```

## Core Components

### 1. ILProtectionHook.sol

The main hook contract that integrates with Uniswap v4's PoolManager. It:

- Implements the `BaseHook` interface from Uniswap v4
- Monitors liquidity position changes via `beforeModifyPosition` and `afterModifyPosition`
- Calculates impermanent loss when positions are modified
- Triggers protection when IL exceeds user's encrypted threshold
- Interacts with the FHE system to maintain privacy

**Key Functions:**
- `beforeModifyPosition()` - Called before a position is modified
- `afterModifyPosition()` - Called after a position is modified
- `calculateCurrentIL()` - Calculates current impermanent loss for a position
- `triggerProtection()` - Initiates protection when IL threshold is breached

### 2. ILCalculator.sol

A library that provides mathematical functions for calculating impermanent loss:

- `calculateIL()` - Main IL calculation function
- `sqrtPriceX96ToPrice()` - Converts Uniswap v4's sqrtPriceX96 format to regular price
- `sqrt()` - Square root function using Babylonian method
- `validateILThreshold()` - Validates IL threshold parameters

**IL Formula:**
```
IL = 2 * sqrt(priceRatio) / (1 + priceRatio) - 1
where priceRatio = currentPrice / entryPrice
```

### 3. FHEManager.sol

Interface to the FHE system that enables:

- Encryption of user IL thresholds
- Comparison operations on encrypted data
- Privacy-preserving condition checks
- Integration with Fhenix network's FHE capabilities

## Uniswap v4 Hook Integration

### Hook System Overview

Uniswap v4 introduces a hook system that allows custom logic to be executed at key points in the pool lifecycle. PILI uses this system to:

1. **Monitor Position Changes**: Track when LPs add/remove liquidity
2. **Calculate IL**: Compute impermanent loss in real-time
3. **Trigger Protection**: Automatically execute protection when needed

### Hook Callbacks

PILI implements several hook callbacks:

- `beforeModifyPosition`: Captures the state before a position change
- `afterModifyPosition`: Calculates IL after the change and triggers protection if needed
- `beforeSwap`: Can be used to monitor price changes that affect IL

### Integration with FHE

The integration of Uniswap hooks with FHE provides:

1. **Privacy**: User IL thresholds remain encrypted
2. **Automatic Execution**: Protection triggers without revealing thresholds
3. **Composability**: Works with any Uniswap v4 pool
4. **Efficiency**: On-chain calculation with encrypted comparison

## FHE Integration Details

### Privacy Model

PILI uses FHE to maintain privacy of:

1. **IL Thresholds**: Each user's maximum acceptable impermanent loss
2. **Position Data**: Sensitive information about liquidity positions
3. **Trigger Conditions**: When protection is activated

### FHE Operations

The system performs these FHE operations:

1. **Encryption**: User thresholds are encrypted using FHE
2. **Comparison**: IL is compared against encrypted thresholds
3. **Condition Checking**: Determines if protection should trigger
4. **Result Verification**: Ensures correct execution without revealing data

### Fhenix Network Integration

PILI is designed to deploy on the Fhenix network, which provides:

- Native FHE support at the blockchain level
- Efficient encrypted computation
- Developer-friendly FHE APIs
- Compatibility with existing Ethereum tooling

## Testing Strategy

### Test Categories

1. **Unit Tests**: Test individual functions in isolation
2. **Integration Tests**: Test contract interactions
3. **FHE Tests**: Test encrypted operations with mocks
4. **Hook Tests**: Test Uniswap v4 hook integration

### Key Test Files

#### ILCalculator.t.sol

Tests the IL calculation logic:

- `testCalculateIL_PriceDoubles()`: Tests IL when price doubles
- `testCalculateIL_PriceUnchanged()`: Verifies IL is 0 when price doesn't change
- `testCalculateIL_SmallPriceIncrease()`: Tests small price changes
- `testCalculateIL_PriceHalves()`: Tests when price halves
- `testCalculateIL_PriceCrash90Percent()`: Tests extreme price drops
- `testCalculatePositionValue()`: Tests position value calculations
- `testSqrt()`: Tests square root function

#### ILCalculatorDebugTest.sol

Debug tests with detailed logging:

- `testDebugPriceConversion()`: Verifies sqrtPriceX96 to price conversion
- `testDebugPriceRatio()`: Tests price ratio calculations
- `testDebugILCalculation()`: Step-by-step IL calculation verification

#### MockFHEManager.sol

Mock implementation for testing:

- Simulates FHE operations without requiring actual FHE
- Provides deterministic behavior for tests
- Enables local testing without Fhenix network

### Test Data

Tests use realistic sqrtPriceX96 values:

- Entry price: `79228162514264337593543950336` (sqrt(1) * 2^96)
- 20% decrease: `70871189684289689689689689680` (sqrt(0.8) * 2^96)
- 20% increase: `86774992596584993989689689680` (sqrt(1.2) * 2^96)

## Deployment

### Prerequisites

1. Node.js and npm installed
2. Foundry installed
3. Private key with funds for deployment
4. Access to Fhenix network (or compatible testnet)

### Deployment Steps

1. Set up environment variables in `.env`:
   ```
   PRIVATE_KEY=your_private_key
   FHENIX_RPC_URL=https://api.helium.fhenix.zone
   ```

2. Compile contracts:
   ```bash
   forge build
   ```

3. Run deployment script:
   ```bash
   forge script script/DeployPiliSystem.s.sol:DeployPiliSystem --rpc-url $FHENIX_RPC_URL --broadcast
   ```

4. Verify deployment:
   ```bash
   forge verify-contract <contract_address> <contract_name> --chain-id 8008135
   ```

## Usage

### For Liquidity Providers

1. **Approve**: Approve the PILI contract to manage your LP tokens
2. **Set Threshold**: Encrypt and set your IL threshold
3. **Provide Liquidity**: Add liquidity to any Uniswap v4 pool
4. **Automatic Protection**: PILI monitors and protects against IL

### For Pool Integrators

1. **Deploy**: Deploy PILI on your preferred network
2. **Configure**: Set up supported pools and parameters
3. **Integrate**: Add PILI as a hook to your pools
4. **Monitor**: Track protection events and user positions

## Security Considerations

1. **FHE Security**: Relies on Fhenix network's FHE implementation
2. **Hook Security**: Follows Uniswap v4 hook security best practices
3. **Access Control**: Proper access controls for admin functions
4. **Oracle Security**: Reliable price feeds for accurate IL calculation

## Future Enhancements

1. **Multi-Asset Support**: Extend beyond ETH/USDC pairs
2. **Dynamic Thresholds**: Allow threshold adjustment over time
3. **Yield Integration**: Combine with yield strategies
4. **Cross-Chain**: Expand to multiple networks

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.