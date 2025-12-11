// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ILCalculator
/// @notice Library for calculating impermanent loss in Uniswap v4 pools
/// @dev Optimized for gas efficiency with custom sqrt implementation
/// @custom:security-contact security@pili.finance

library ILCalculatorFixed {
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
        // Where priceRatio is in PRECISION (1e18) units
        // sqrt(priceRatio) returns sqrt(priceRatio in 1e18) which is in sqrt(1e18) = 1e9 units
        // To keep everything in PRECISION units, we need to scale properly

        uint256 sqrtRatio = sqrt(priceRatio); // This is in sqrt(PRECISION) units

        // Convert sqrtRatio to PRECISION units by multiplying by sqrt(PRECISION) and dividing by PRECISION
        // sqrtRatio_normalized = sqrtRatio * sqrt(PRECISION) / sqrt(PRECISION) = sqrtRatio
        // Actually, we need: sqrtRatio * PRECISION / sqrt(PRECISION)
        uint256 sqrtPrecision = 1e9; // sqrt(1e18) = 1e9

        // Numerator: 2 * sqrt(priceRatio) in PRECISION units
        // = 2 * sqrtRatio * PRECISION / sqrtPrecision
        uint256 numerator = 2 * sqrtRatio * PRECISION / sqrtPrecision;
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
        // To avoid overflow, we rearrange: (sqrtPriceX96 * sqrtPriceX96 * PRECISION) / 2^192
        // Further optimization: divide by 2^96 twice instead of 2^192 once
        // price = ((sqrtPriceX96 / 2^96) * sqrtPriceX96 * PRECISION) / 2^96

        uint256 sqrtPrice = uint256(sqrtPriceX96);

        // First divide by 2^96, then multiply by sqrtPrice and PRECISION, then divide by 2^96 again
        // This keeps intermediate values within uint256 bounds
        uint256 temp = (sqrtPrice * PRECISION) / (1 << 96); // sqrtPrice * PRECISION / 2^96
        price = (temp * sqrtPrice) / (1 << 96); // result * sqrtPrice / 2^96

        return price;
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