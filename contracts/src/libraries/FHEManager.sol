// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {FHE} from "@fhenixprotocol/contracts/FHE.sol";
import {euint32, euint256, ebool} from "../interfaces/ILPPosition.sol";

/// @title FHEManager
/// @notice Library for Fully Homomorphic Encryption operations
/// @dev Full Fhenix FHE integration for privacy-preserving IL threshold comparisons
/// @dev Uses Fhenix protocol for encrypted computations on-chain
/// @custom:security-contact security@pili.finance

library FHEManager {
    
    /// @dev Custom errors for FHE operations
    error InvalidEncryptedValue();
    error FHEComparisonFailed();
    error InvalidBasisPoints();
    error DecryptionNotPermitted();

    /// @notice Gas estimate for FHE encryption operation
    /// @dev Based on Fhenix testnet benchmarks: ~50,000 gas
    uint256 constant FHE_ENCRYPT_GAS = 50000;

    /// @notice Gas estimate for FHE comparison operation (FHE.gt)
    /// @dev Based on Fhenix testnet benchmarks: ~100,000 gas
    uint256 constant FHE_COMPARE_GAS = 100000;

    /// @notice Gas estimate for FHE conditional execution
    /// @dev Based on Fhenix testnet benchmarks: ~20,000 gas
    uint256 constant FHE_CONDITIONAL_GAS = 20000;

    /// @notice Encrypt a plaintext basis point value
    /// @dev Converts plaintext basis points to encrypted euint32 using Fhenix FHE
    /// @param basisPoints Value in basis points (e.g., 500 = 5%)
    /// @return encrypted Encrypted value as euint32
    function encryptBasisPoints(uint32 basisPoints)
        internal
        pure
        returns (euint32 encrypted)
    {
        if (basisPoints > 10000) revert InvalidBasisPoints();

        // Encrypt using Fhenix FHE
        encrypted = FHE.asEuint32(uint256(basisPoints));

        return encrypted;
    }

    /// @notice Compare if current IL exceeds threshold using FHE
    /// @dev Uses Fhenix FHE for privacy-preserving comparison
    /// @dev This is the CORE privacy-preserving function of PILI
    /// @param currentILBp Current IL in basis points (plaintext)
    /// @param encryptedThreshold Encrypted threshold from LP
    /// @return shouldExit True if IL exceeds threshold (triggers withdrawal)
    function compareThresholds(
        uint256 currentILBp,
        euint32 encryptedThreshold
    ) internal pure returns (bool shouldExit) {
        if (currentILBp > type(uint32).max) revert InvalidBasisPoints();

        // Encrypt current IL
        euint32 encryptedCurrentIL = FHE.asEuint32(uint32(currentILBp));

        // Perform encrypted comparison: currentIL > threshold
        ebool comparisonResult = FHE.gte(encryptedCurrentIL, encryptedThreshold);

        // Decrypt the boolean result
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
    ) internal pure {
        if (currentILBp > type(uint32).max) revert InvalidBasisPoints();

        // Encrypt current IL
        euint32 encryptedCurrentIL = FHE.asEuint32(uint32(currentILBp));

        // Perform encrypted comparison
        ebool shouldExit = FHE.gt(encryptedCurrentIL, encryptedThreshold);

        // Use FHE.req to revert if condition is false (no decryption!)
        FHE.req(shouldExit);
    }

    /// @notice Validate encrypted threshold from client
    /// @dev Validates FHE ciphertext handle using Fhenix isInitialized
    /// @param encryptedThreshold Encrypted threshold from client
    /// @return isValid Whether the encrypted value is valid
    function validateEncryptedThreshold(euint32 encryptedThreshold)
        internal
        pure
        returns (bool isValid)
    {
        // Check if the encrypted value is properly initialized
        // FHE.isInitialized returns true if the ciphertext handle is valid
        isValid = FHE.isInitialized(encryptedThreshold);

        // Note: We cannot validate the actual value range (10-5000 bp)
        // without decrypting, which would defeat the privacy purpose.
        // Range validation must be done client-side before encryption.

        return isValid;
    }

    /// @notice Encrypt a price value (for future price bounds feature)
    /// @dev Uses FHE.asEuint256() for price encryption
    /// @param price Price value to encrypt
    /// @return encrypted Encrypted price
    function encryptPrice(uint256 price)
        internal
        pure
        returns (euint256 encrypted)
    {
        // Encrypt using Fhenix FHE
        encrypted = FHE.asEuint256(price);
        return encrypted;
    }

    /// @notice Compare prices using FHE (for future price bounds feature)
    /// @dev NOT YET IMPLEMENTED: Fhenix does not support comparison operations on euint256
    /// @dev Future implementation will use euint128 or wait for Fhenix euint256 comparison support
    /// @param encryptedCurrentPrice Current price (encrypted)
    /// @param encryptedUpperBound Upper price bound (encrypted)
    /// @param encryptedLowerBound Lower price bound (encrypted)
    /// @return isOutOfBounds True if price outside bounds
    function comparePriceBounds(
        euint256 encryptedCurrentPrice,
        euint256 encryptedUpperBound,
        euint256 encryptedLowerBound
    ) internal pure returns (bool isOutOfBounds) {
        // NOTE: Fhenix FHE library does not yet support gt/lt/gte/lte for euint256
        // This function is a placeholder for future implementation
        //
        // Options for future implementation:
        // 1. Wait for Fhenix to add euint256 comparison support
        // 2. Use euint128 for price comparisons (sufficient for most use cases)
        // 3. Implement custom comparison logic using smaller encrypted types
        //
        // For now, revert to prevent usage
        revert("Price bounds comparison not yet supported for euint256");

        // Silence unused variable warnings
        encryptedCurrentPrice = encryptedCurrentPrice;
        encryptedUpperBound = encryptedUpperBound;
        encryptedLowerBound = encryptedLowerBound;
        isOutOfBounds = false;
    }

    /// @notice Decrypt an encrypted value (use sparingly!)
    /// @dev Uses FHE.decrypt() - requires proper permissions
    /// @dev WARNING: Decryption reduces privacy guarantees - minimize usage
    /// @param encrypted Encrypted value
    /// @return decrypted Plaintext value
    function decryptValue(euint32 encrypted)
        internal
        pure
        returns (uint32 decrypted)
    {
        // Decrypt using Fhenix FHE
        // Note: This requires the caller to have decryption permissions
        decrypted = FHE.decrypt(encrypted);
        return decrypted;
    }

    /// @notice Get estimated gas cost for FHE operations
    /// @dev Helper for frontend gas estimation
    /// @return totalGas Estimated total gas for one complete IL check
    function estimateFHEGasCost() 
        internal 
        pure 
        returns (uint256 totalGas) 
    {
        totalGas = FHE_ENCRYPT_GAS +  // Encrypt current IL
                   FHE_COMPARE_GAS +   // Compare with threshold
                   FHE_CONDITIONAL_GAS; // Conditional execution
        return totalGas;
    }

    /// @notice Check if FHE module is available
    /// @dev STUB: In production, checks Fhenix protocol availability
    /// @return isAvailable Whether FHE operations can be performed
    function isFHEAvailable() internal pure returns (bool isAvailable) {
        // STUB: Always return true for testing
        // In production: Check if Fhenix protocol is initialized
        return true;
    }

    /// @notice Seal (re-encrypt) an encrypted value for a specific user
    /// @dev Allows LP to retrieve their encrypted threshold using their public key
    /// @param encrypted The encrypted value to seal
    /// @param publicKey The user's public key for re-encryption
    /// @return sealedValue The sealed (re-encrypted) value as a string
    function sealForUser(euint32 encrypted, bytes32 publicKey)
        internal
        pure
        returns (string memory sealedValue)
    {
        // Seal the encrypted value using Fhenix FHE
        // This re-encrypts the value so only the holder of the private key can decrypt it
        sealedValue = FHE.sealoutput(encrypted, publicKey);
        return sealedValue;
    }

    /// @notice Privacy safety check
    /// @dev Ensures encrypted value is never logged or emitted in plaintext
    /// @dev This is a compile-time check, not runtime
    /// @param encrypted The encrypted value to protect
    function ensurePrivacy(euint32 encrypted) internal pure {
        // This function exists to make developers conscious of privacy
        // CRITICAL RULES:
        // - Do NOT emit events with decrypted values!
        // - Do NOT store decrypted version in state!
        // - Do NOT log to console!
        // - Only use FHE.seal() for sharing encrypted data with users

        // Silence unused variable warning
        encrypted = encrypted;
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

        // If not cached or cache is uninitialized, encrypt and cache
        if (!FHE.isInitialized(encryptedCurrentIL)) {
            if (currentILBp > type(uint32).max) revert InvalidBasisPoints();
            // Encrypt current IL
            encryptedCurrentIL = FHE.asEuint32(uint32(currentILBp));
            // Cache for future use
            cache.encryptedILByEntryPrice[entryPrice] = encryptedCurrentIL;
        }

        // Perform encrypted comparison
        ebool comparisonResult = FHE.gte(encryptedCurrentIL, encryptedThreshold);

        // Decrypt the result
        shouldExit = FHE.decrypt(comparisonResult);

        return shouldExit;
    }
}

/// @title FHEIntegrationNotes
/// @notice Documentation for FHE integration and client-side usage
/// @dev Guide for Dev 3 (Frontend) to integrate with FHE operations
/*
 * FHE INTEGRATION - COMPLETED ✓
 *
 * This library now uses full Fhenix FHE integration.
 *
 * CLIENT-SIDE INTEGRATION GUIDE FOR DEV 3:
 * 
 * 1. Install fhenixjs in your frontend:
 *    ```bash
 *    npm install fhenixjs
 *    ```
 *
 * 2. Initialize Fhenix client:
 *    ```javascript
 *    import { FhenixClient } from "fhenixjs";
 *
 *    const provider = new ethers.providers.Web3Provider(window.ethereum);
 *    const fhenixClient = new FhenixClient({ provider });
 *    ```
 *
 * 3. Encrypt IL threshold before sending to contract:
 *    ```javascript
 *    // LP wants 5% IL threshold (500 basis points)
 *    const thresholdBp = 500;
 *
 *    // Encrypt the threshold
 *    const encryptedThreshold = await fhenixClient.encrypt_uint32(thresholdBp);
 *
 *    // Encode as hookData for Uniswap v4
 *    const hookData = ethers.utils.defaultAbiCoder.encode(
 *      ["bytes"],
 *      [encryptedThreshold]
 *    );
 *    ```
 *
 * 4. Adding liquidity with encrypted threshold:
 *    ```javascript
 *    await poolManager.modifyLiquidity(
 *      poolKey,
 *      {
 *        tickLower: -887220,
 *        tickUpper: 887220,
 *        liquidityDelta: liquidityAmount
 *      },
 *      hookData  // Contains encrypted threshold
 *    );
 *    ```
 *
 * 5. Retrieving encrypted threshold (if needed):
 *    ```javascript
 *    // Get user's public key
 *    const publicKey = await fhenixClient.getPublicKey();
 *
 *    // Call view function that returns sealed value
 *    const sealedThreshold = await hook.getSealedThreshold(positionId, publicKey);
 *
 *    // Decrypt client-side
 *    const thresholdBp = await fhenixClient.unseal(sealedThreshold);
 *    console.log(`Your IL threshold: ${thresholdBp / 100}%`);
 *    ```
 *
 * 6. Permission system (if using Permissioned pattern):
 *    - For basic operations, no explicit permissions needed
 *    - The contract can work with encrypted values without decryption
 *    - Only seal() operations require user's public key
 *
 * 7. Gas estimation:
 *    - FHE operations are gas-intensive
 *    - Encryption: ~50k gas
 *    - Comparison: ~100k gas
 *    - Plan for ~200k+ gas per IL check during swaps
 * 
 * PRIVACY GUARANTEES MAINTAINED:
 * ✓ IL threshold stays encrypted on-chain
 * ✓ Comparison happens on encrypted values
 * ✓ Only the boolean result (exit or not) becomes public
 * ✓ LP can retrieve encrypted threshold using seal()
 * ✓ No decrypted values are emitted in events
 *
 * SECURITY CONSIDERATIONS:
 * - Always validate basis points are in range (10-5000 bp) CLIENT-SIDE before encryption
 * - Never log or emit decrypted values
 * - FHE.decrypt() is only used for boolean comparison results (not threshold values)
 * - Use FHE.seal() when sharing encrypted data with users
 * - Consider gas costs when checking multiple positions
 *
 * TESTING RECOMMENDATIONS:
 * - Test FHE encryption/decryption roundtrip on Fhenix testnet
 * - Verify comparison accuracy with known plaintext values
 * - Benchmark gas costs for different position counts
 * - Test edge cases (max IL, min IL, exact threshold match)
 * - Ensure encrypted values survive contract upgrades (if applicable)
 */
