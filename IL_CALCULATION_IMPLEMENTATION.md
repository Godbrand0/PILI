# IL (Impermanent Loss) Calculation Implementation

## Overview
This document describes the implementation of IL calculation logic for the PILI project, which provides impermanent loss protection for Uniswap v4 liquidity providers.

## Key Changes Made

### 1. Contract Implementation (`contracts/src/libraries/ILCalculator.sol`)

**Problem**: The original implementation was expecting regular prices but Uniswap v4 uses `sqrtPriceX96` format.

**Solution**:
- Updated `calculateIL()` function to accept `sqrtPriceX96` values
- Added conversion from `sqrtPriceX96` to regular price using the formula:
  ```
  price = (sqrtPriceX96^2) / 2^192
  ```
- Added `calculateILWithLogging()` function for debugging with intermediate values

### 2. Hook Contract Updates (`contracts/src/ILProtectionHook.sol`)

**Problem**: The hook was using hardcoded prices (`1e18`) instead of fetching actual pool prices.

**Solution**:
- Added import for `StateLibrary` to access pool state
- Modified `_afterInitialize()` to accept and store `sqrtPriceX96`
- Updated `_beforeRemoveLiquidity()` and `_beforeSwap()` to:
  - Fetch current `sqrtPriceX96` from pool state using `poolManager.getSlot0(poolId)`
  - Calculate IL using actual prices instead of hardcoded values

### 3. Frontend Implementation (`frontend/lib/utils.ts`)

**Problem**: Frontend was using simplified IL calculation that didn't match the contract implementation.

**Solution**:
- Added `sqrtPriceX96ToPrice()` conversion function
- Updated `calculateImpermanentLoss()` to work with `sqrtPriceX96` values
- Added debug logging to console for troubleshooting
- Added `calculateImpermanentLossFromPrices()` for backward compatibility

### 4. Component Updates (`frontend/components/PositionCard.tsx`)

**Changes**:
- Updated to accept `currentSqrtPriceX96` prop instead of separate token prices
- Modified IL calculation to use the new utility function

## IL Calculation Formula

The impermanent loss formula used is:
```
IL = (2 * sqrt(priceRatio) / (1 + priceRatio)) - 1
```

Where:
- `priceRatio = currentPrice / entryPrice`
- Prices are converted from `sqrtPriceX96` to regular prices before calculation
- Result is returned as basis points (1% = 100 basis points)

## Testing

Created test files to validate:
1. No price change → 0% IL
2. 10% price decrease → ~0.47% IL
3. 50% price decrease → ~5.72% IL
4. `sqrtPriceX96` to price conversion accuracy

## Debug Logging

Added logging at multiple levels:
1. Contract level: `calculateILWithLogging()` shows intermediate values
2. Frontend level: Console logs show conversion steps and final IL percentage

## Usage

### Contract
```solidity
uint256 ilBp = ILCalculator.calculateIL(entrySqrtPriceX96, currentSqrtPriceX96);
```

### Frontend
```javascript
const il = calculateImpermanentLoss(entrySqrtPriceX96, currentSqrtPriceX96);
```

## Key Insights

1. **Price Format Matters**: Uniswap v4's `sqrtPriceX96` format must be properly converted to regular prices for IL calculation
2. **Real-time Data**: The hook now fetches current prices from pool state during each swap/liquidity change
3. **Consistency**: Both contract and frontend now use the same IL calculation logic
4. **Debuggability**: Added logging throughout the stack to troubleshoot issues

## Next Steps

1. Deploy updated contracts to testnet
2. Test with actual pool operations
3. Monitor IL calculations in production
4. Optimize gas usage if needed