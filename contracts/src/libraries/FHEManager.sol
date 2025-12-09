// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@fhenixprotocol/contracts/FHE.sol";

/// @title FHEManager
/// @notice Library for FHE operations in IL Protection Hook
/// @dev Implements Approach 1: Minimal Decryption Pattern
library FHEManager {
    
    /// @notice Encrypt a plaintext basis point value
    /// @param basisPoints Value in basis points (e.g., 500 = 5%)
    /// @return encrypted Encrypted value as euint32
    function encryptBasisPoints(uint32 basisPoints)
        internal
        pure
        returns (euint32 encrypted)
    {
        require(basisPoints <= 10000, "FHEManager: Invalid basis points");
        encrypted = FHE.asEuint32(basisPoints);
        return encrypted;
    }

    /// @notice Compare if current IL exceeds threshold using FHE (Approach 1)
    /// @param currentILBp Current IL in basis points (plaintext)
    /// @param encryptedThreshold Encrypted threshold
    /// @return shouldExit True if IL exceeds threshold
    /// @dev This is the core of Approach 1: minimal decryption pattern
    function compareThresholds(
        uint256 currentILBp,
        euint32 encryptedThreshold
    ) internal returns (bool shouldExit) {
        require(currentILBp <= type(uint32).max, "FHEManager: IL too large");

        // Encrypt current IL for comparison
        euint32 encryptedCurrentIL = FHE.asEuint32(uint32(currentILBp));

        // FHE comparison: currentIL > threshold?
        ebool comparisonResult = FHE.gt(encryptedCurrentIL, encryptedThreshold);

        // Minimal decryption - only decrypt the boolean result
        // Threshold value remains encrypted throughout
        shouldExit = FHE.decrypt(comparisonResult);

        return shouldExit;
    }

    /// @notice Compare using FHE.req (Approach 2 - zero decryption)
    /// @param currentILBp Current IL in basis points
    /// @param encryptedThreshold Encrypted threshold
    /// @dev Reverts if currentIL <= threshold, proceeds if currentIL > threshold
    /// @dev This is for Approach 2 compatibility - not used in main implementation
    function requireThresholdBreached(
        uint256 currentILBp,
        euint32 encryptedThreshold
    ) internal {
        require(currentILBp <= type(uint32).max, "FHEManager: IL too large");

        euint32 encryptedCurrentIL = FHE.asEuint32(uint32(currentILBp));
        ebool shouldExit = FHE.gt(encryptedCurrentIL, encryptedThreshold);

        // Enforce condition - reverts if false
        FHE.req(shouldExit);
    }

    /// @notice Validate encrypted threshold (client-provided)
    /// @param encryptedThreshold Encrypted threshold from client
    /// @return isValid Whether the encrypted value is valid
    function validateEncryptedThreshold(euint32 encryptedThreshold)
        internal
        pure
        returns (bool isValid)
    {
        // Basic validation - ensure not zero handle
        return euint32.unwrap(encryptedThreshold) != 0;
    }

    /// @notice Encrypt price value (for price bounds feature)
    /// @param price Price value to encrypt
    /// @return encrypted Encrypted price as euint256
    function encryptPrice(uint256 price)
        internal
        pure
        returns (euint256 encrypted)
    {
        encrypted = FHE.asEuint256(price);
        return encrypted;
    }

    /// @notice Compare prices using FHE (for price bounds feature)
    /// @param encryptedCurrentPrice Current price (encrypted)
    /// @param encryptedUpperBound Upper price bound (encrypted)
    /// @param encryptedLowerBound Lower price bound (encrypted)
    /// @return isOutOfBounds True if price outside bounds
    function comparePriceBounds(
        euint256 encryptedCurrentPrice,
        euint256 encryptedUpperBound,
        euint256 encryptedLowerBound
    ) internal returns (bool isOutOfBounds) {
        // Check if price > upper OR price < lower
        ebool aboveUpper = FHE.gt(encryptedCurrentPrice, encryptedUpperBound);
        ebool belowLower = FHE.lt(encryptedCurrentPrice, encryptedLowerBound);

        // OR operation (at least one is true)
        ebool outOfBounds = FHE.or(aboveUpper, belowLower);

        isOutOfBounds = FHE.decrypt(outOfBounds);
        return isOutOfBounds;
    }

    // ============ P0 ENHANCEMENTS ============

    /// @notice FHE cache for gas optimization
    /// @dev Stores encrypted IL values by entry price to avoid re-encryption
    struct FHECache {
        mapping(uint256 => euint32) encryptedILByEntryPrice;
    }

    /// @notice Compare thresholds with caching (P0 optimization)
    /// @param currentILBp Current IL in basis points
    /// @param entryPrice Entry price (used as cache key)
    /// @param encryptedThreshold Encrypted threshold
    /// @param cache FHE cache storage
    /// @return shouldExit True if IL exceeds threshold
    /// @dev Saves ~50k gas when multiple positions share same entry price
    function compareThresholdsWithCache(
        uint256 currentILBp,
        uint256 entryPrice,
        euint32 encryptedThreshold,
        FHECache storage cache
    ) internal returns (bool shouldExit) {
        // Check cache first
        euint32 encryptedCurrentIL = cache.encryptedILByEntryPrice[entryPrice];
        
        if (euint32.unwrap(encryptedCurrentIL) == 0) {
            // Not cached - encrypt and cache
            require(currentILBp <= type(uint32).max, "FHEManager: IL too large");
            encryptedCurrentIL = FHE.asEuint32(uint32(currentILBp));
            cache.encryptedILByEntryPrice[entryPrice] = encryptedCurrentIL;
        }
        
        // Compare using cached encrypted value
        ebool result = FHE.gt(encryptedCurrentIL, encryptedThreshold);
        return FHE.decrypt(result);
    }
}
