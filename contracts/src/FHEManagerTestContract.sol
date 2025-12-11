// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./libraries/FHEManager.sol";
import "./interfaces/ILPPosition.sol";

/// @title FHEManagerTestContract
/// @notice Test contract to verify FHEManager functionality
/// @dev This contract can be deployed to Fhenix testnet for integration testing
contract FHEManagerTestContract {
    using FHEManager for *;

    // Events for testing
    event ThresholdCompared(uint256 currentIL, bool shouldExit);
    event BasisPointsEncrypted(uint32 basisPoints);
    event PriceBoundsChecked(bool isOutOfBounds);

    /// @notice Test encrypting basis points
    /// @param basisPoints Value to encrypt (e.g., 500 = 5%)
    /// @return encrypted The encrypted value
    function testEncryptBasisPoints(uint32 basisPoints)
        external
        returns (euint32 encrypted)
    {
        encrypted = FHEManager.encryptBasisPoints(basisPoints);
        emit BasisPointsEncrypted(basisPoints);
        return encrypted;
    }

    /// @notice Test threshold comparison (Approach 1)
    /// @param currentILBp Current IL in basis points
    /// @param thresholdBp Threshold in basis points (will be encrypted)
    /// @return shouldExit True if IL exceeds threshold
    function testCompareThresholds(uint256 currentILBp, uint32 thresholdBp)
        external
        returns (bool shouldExit)
    {
        // Encrypt the threshold
        euint32 encryptedThreshold = FHEManager.encryptBasisPoints(thresholdBp);

        // Use the async comparison function (deprecated but returns a value)
        shouldExit = FHEManager.compareThresholdsAsync(
            currentILBp,
            encryptedThreshold
        );

        emit ThresholdCompared(currentILBp, shouldExit);
        return shouldExit;
    }

    /// @notice Test threshold comparison with pre-encrypted threshold
    /// @param currentILBp Current IL in basis points
    /// @param encryptedThreshold Pre-encrypted threshold
    /// @return shouldExit True if IL exceeds threshold
    function testCompareThresholdsWithEncrypted(
        uint256 currentILBp,
        euint32 encryptedThreshold
    ) external returns (bool shouldExit) {
        // Use the async comparison function (deprecated but returns a value)
        shouldExit = FHEManager.compareThresholdsAsync(
            currentILBp,
            encryptedThreshold
        );

        emit ThresholdCompared(currentILBp, shouldExit);
        return shouldExit;
    }

    /// @notice Test FHE.req approach (Approach 2)
    /// @param currentILBp Current IL in basis points
    /// @param thresholdBp Threshold in basis points
    /// @dev Reverts if threshold not breached
    function testRequireThresholdBreached(uint256 currentILBp, uint32 thresholdBp)
        external
    {
        euint32 encryptedThreshold = FHEManager.encryptBasisPoints(thresholdBp);
        FHEManager.requireThresholdBreached(currentILBp, encryptedThreshold);
    }

    /// @notice Test price encryption
    /// @param price Price value to encrypt
    /// @return encrypted Encrypted price
    function testEncryptPrice(uint256 price)
        external
        pure
        returns (euint256 encrypted)
    {
        encrypted = FHEManager.encryptPrice(price);
        return encrypted;
    }

    /// @notice Test price bounds comparison
    /// @param currentPrice Current price
    /// @param upperBound Upper price bound
    /// @param lowerBound Lower price bound
    /// @return isOutOfBounds True if price is outside bounds
    function testComparePriceBounds(
        uint256 currentPrice,
        uint256 upperBound,
        uint256 lowerBound
    ) external returns (bool isOutOfBounds) {
        // Encrypt all prices
        euint256 encryptedCurrent = FHEManager.encryptPrice(currentPrice);
        euint256 encryptedUpper = FHEManager.encryptPrice(upperBound);
        euint256 encryptedLower = FHEManager.encryptPrice(lowerBound);
        
        // Compare
        isOutOfBounds = FHEManager.comparePriceBounds(
            encryptedCurrent,
            encryptedUpper,
            encryptedLower
        );
        
        emit PriceBoundsChecked(isOutOfBounds);
        return isOutOfBounds;
    }

    /// @notice Validate encrypted threshold
    /// @param encryptedThreshold Threshold to validate
    /// @return isValid True if valid
    function testValidateEncryptedThreshold(euint32 encryptedThreshold)
        external
        pure
        returns (bool isValid)
    {
        isValid = FHEManager.validateEncryptedThreshold(encryptedThreshold);
        return isValid;
    }

    /// @notice Test multiple scenarios in one transaction
    /// @return results Array of test results
    function runAllTests() external returns (bool[5] memory results) {
        // Test 1: Encrypt 500 bp (5%)
        euint32 threshold = FHEManager.encryptBasisPoints(500);
        results[0] = euint32.unwrap(threshold) != 0;
        
        // Test 2: Compare 600 bp > 500 bp (should exit)
        results[1] = FHEManager.compareThresholds(600, threshold);
        
        // Test 3: Compare 300 bp > 500 bp (should not exit)
        results[2] = !FHEManager.compareThresholds(300, threshold);
        
        // Test 4: Validate threshold
        results[3] = FHEManager.validateEncryptedThreshold(threshold);
        
        // Test 5: Price encryption
        euint256 price = FHEManager.encryptPrice(2000e18);
        results[4] = euint256.unwrap(price) != 0;
        
        return results;
    }
}
