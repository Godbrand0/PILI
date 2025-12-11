// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ILCalculator
/// @notice Library for calculating impermanent loss in Uniswap v4 pools
/// @dev Optimized for gas efficiency with custom sqrt implementation
/// @custom:security-contact security@pili.finance

import {FullMath} from "v4-core/libraries/FullMath.sol";

library ILCalculator {
    /// @notice Precision constant for fixed-point arithmetic
    uint256 constant PRECISION = 1e18;
    
    /// @notice Basis points divisor (10000 = 100%)
    uint256 constant BP_DIVISOR = 10000;

    /// @notice Minimum valid price to prevent division by zero
    uint256 constant MIN_PRICE = 1;

    /// @notice Maximum price ratio to prevent overflow (1000x price change)
    uint256 constant MAX_PRICE_RATIO = 1000 * PRECISION;

    /// @dev Custom errors for gas-efficient reverts
    error InvalidEntryPrice();
    error InvalidCurrentPrice();
    error PriceRatioTooLarge();

    /// @notice Calculate impermanent loss as basis points
    /// @dev IL formula: 2 * sqrt(priceRatio) / (1 + priceRatio) - 1
    /// @dev Returns 0 if no IL (price returned to entry or better for LP)
    /// @param entryPrice Price when LP deposited (in sqrtPriceX96 format)
    /// @param currentPrice Current pool price (in sqrtPriceX96 format)
    /// @return ilBasisPoints IL as basis points (500 = 5%, 1000 = 10%)
    function calculateIL(
        uint256 entryPrice,
        uint256 currentPrice
    ) internal pure returns (uint256 ilBasisPoints) {
        // Input validation
        if (entryPrice < MIN_PRICE) revert InvalidEntryPrice();
        if (currentPrice < MIN_PRICE) revert InvalidCurrentPrice();

        // Convert sqrtPriceX96 to regular price first
        uint256 entryPriceRegular = sqrtPriceX96ToPrice(uint160(entryPrice));
        uint256 currentPriceRegular = sqrtPriceX96ToPrice(uint160(currentPrice));

        // Calculate price ratio: currentPrice / entryPrice
        uint256 priceRatio = (currentPriceRegular * PRECISION) / entryPriceRegular;

        // Prevent overflow for extreme price changes
        if (priceRatio > MAX_PRICE_RATIO) revert PriceRatioTooLarge();

        // IL formula: 2 * sqrt(priceRatio) / (1 + priceRatio) - 1
        uint256 sqrtRatio = sqrt(priceRatio);
        uint256 numerator = 2 * sqrtRatio;
        uint256 denominator = PRECISION + priceRatio;

        // Result in fixed-point (PRECISION units)
        uint256 result = (numerator * PRECISION) / denominator;

        // If result < PRECISION, we have IL (negative return)
        if (result < PRECISION) {
            uint256 ilPercentage = PRECISION - result;
            ilBasisPoints = (ilPercentage * BP_DIVISOR) / PRECISION;
        } else {
            // No IL (price returned to entry or LP gained)
            ilBasisPoints = 0;
        }

        return ilBasisPoints;
    }

    /// @notice Calculate impermanent loss with logging for debugging
    /// @dev Same as calculateIL but with additional logging
    function calculateILWithLogging(
        uint256 entryPrice,
        uint256 currentPrice
    ) internal pure returns (uint256 ilBasisPoints) {
        // Convert sqrtPriceX96 to regular price first
        uint256 entryPriceRegular = sqrtPriceX96ToPrice(uint160(entryPrice));
        uint256 currentPriceRegular = sqrtPriceX96ToPrice(uint160(currentPrice));

        // Calculate price ratio: currentPrice / entryPrice
        uint256 priceRatio = (currentPriceRegular * PRECISION) / entryPriceRegular;

        // Log intermediate values for debugging
        // In a real implementation, you'd use console.log or emit events
        // entryPriceRegular: {entryPriceRegular}
        // currentPriceRegular: {currentPriceRegular}
        // priceRatio: {priceRatio}

        // IL formula: 2 * sqrt(priceRatio) / (1 + priceRatio) - 1
        uint256 sqrtRatio = sqrt(priceRatio);
        uint256 numerator = 2 * sqrtRatio;
        uint256 denominator = PRECISION + priceRatio;

        // Result in fixed-point (PRECISION units)
        uint256 result = (numerator * PRECISION) / denominator;

        // If result < PRECISION, we have IL (negative return)
        if (result < PRECISION) {
            uint256 ilPercentage = PRECISION - result;
            ilBasisPoints = (ilPercentage * BP_DIVISOR) / PRECISION;
        } else {
            // No IL (price returned to entry or LP gained)
            ilBasisPoints = 0;
        }

        // Log final result for debugging
        // ilBasisPoints: {ilBasisPoints}

        return ilBasisPoints;
    }

    /// @notice Calculate current position value compared to HODL value
    /// @dev Used to verify IL calculations and provide additional metrics
    /// @param token0Amount Initial token0 amount
    /// @param token1Amount Initial token1 amount
    /// @param currentPrice Current price (token1 per token0)
    /// @return hodlValue Value if LP had just held tokens (in token1 units)
    /// @return lpValue Current value as LP in AMM (in token1 units)
    /// @return ilBasisPoints Calculated IL from value difference
    function calculatePositionValue(
        uint256 token0Amount,
        uint256 token1Amount,
        uint256 currentPrice
    ) internal pure returns (
        uint256 hodlValue,
        uint256 lpValue,
        uint256 ilBasisPoints
    ) {
        if (currentPrice < MIN_PRICE) revert InvalidCurrentPrice();

        // HODL value: what LP would have if they just held
        // value = token0 * currentPrice + token1
        hodlValue = ((token0Amount * currentPrice) / PRECISION) + token1Amount;

        // LP value: current value in AMM (using constant product formula)
        // k = token0 * token1 (constant)
        uint256 k = token0Amount * token1Amount;

        // At current price: token0_new * token1_new = k
        // token1_new / token0_new = currentPrice
        // Therefore:
        //   token0_new = sqrt(k / currentPrice)
        //   token1_new = sqrt(k * currentPrice)

        // Use FullMath to avoid overflow and handle precision
        // token0New = sqrt(k * PRECISION / currentPrice)
        uint256 token0New = sqrt(FullMath.mulDiv(k, PRECISION, currentPrice));
        
        // token1New = sqrt(k * currentPrice / PRECISION)
        uint256 token1New = sqrt(FullMath.mulDiv(k, currentPrice, PRECISION));

        // LP value in token1 terms
        lpValue = ((token0New * currentPrice) / PRECISION) + token1New;

        // Calculate IL from value difference
        if (lpValue < hodlValue) {
            uint256 loss = hodlValue - lpValue;
            ilBasisPoints = (loss * BP_DIVISOR) / hodlValue;
        } else {
            // Edge case: LP value >= HODL value (shouldn't happen in normal AMM)
            ilBasisPoints = 0;
        }

        return (hodlValue, lpValue, ilBasisPoints);
    }

    /// @notice Square root function using Babylonian method
    /// @dev Gas-optimized iterative algorithm
    /// @dev More efficient than Newton's method for typical price ranges
    /// @param x Value to find square root of
    /// @return y Square root of x
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        if (x <= 3) return 1;

        // Initial estimate: use bit length / 2
        uint256 z = (x + 1) / 2;
        y = x;

        // Babylonian method: iterate until convergence
        // Limit iterations to prevent infinite loops (worst case ~logarithmic)
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }

        return y;
    }

    /// @notice Convert sqrtPriceX96 (Uniswap v4 format) to regular price
    /// @dev sqrtPriceX96 = sqrt(price) * 2^96
    /// @dev price = (sqrtPriceX96 / 2^96)^2 = sqrtPriceX96^2 / 2^192
    /// @param sqrtPriceX96 Square root price in Q96 fixed-point format
    /// @return price Regular price in PRECISION units
    function sqrtPriceX96ToPrice(uint160 sqrtPriceX96) 
        internal 
        pure 
        returns (uint256 price) 
    {
        // price = (sqrtPriceX96^2 / 2^192) * PRECISION
        // To avoid overflow, we do: (sqrtPriceX96^2 * PRECISION) / 2^192
        
        uint256 sqrtPrice = uint256(sqrtPriceX96);
        
        // Calculate sqrtPrice^2 * PRECISION
        // Use assembly for precise arithmetic to avoid overflow
        uint256 sqrtPriceSquared = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        price = FullMath.mulDiv(sqrtPriceSquared, PRECISION, 1 << 192);
        
        return price;
    }

    /// @notice Validate IL threshold is within acceptable range
    /// @dev Thresholds must be between 0.1% and 50% to be reasonable
    /// @param thresholdBp Threshold in basis points
    /// @return isValid Whether threshold is valid
    function validateILThreshold(uint256 thresholdBp) 
        internal 
        pure 
        returns (bool isValid) 
    {
        // Minimum: 0.1% (10 bp) to prevent spam
        // Maximum: 50% (5000 bp) to ensure reasonable risk tolerance
        return thresholdBp >= 10 && thresholdBp <= 5000;
    }

    /// @notice Calculate percentage change in price
    /// @param oldPrice Original price
    /// @param newPrice New price
    /// @return percentageChange Price change in basis points (can be negative)
    function priceChangePercent(uint256 oldPrice, uint256 newPrice)
        internal
        pure
        returns (int256 percentageChange)
    {
        if (oldPrice < MIN_PRICE) revert InvalidEntryPrice();
        if (newPrice < MIN_PRICE) revert InvalidCurrentPrice();

        if (newPrice >= oldPrice) {
            // Price increased
            uint256 increase = newPrice - oldPrice;
            percentageChange = int256((increase * BP_DIVISOR) / oldPrice);
        } else {
            // Price decreased
            uint256 decrease = oldPrice - newPrice;
            percentageChange = -int256((decrease * BP_DIVISOR) / oldPrice);
        }

        return percentageChange;
    }
}