// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/libraries/FHEManager.sol";
import "@fhenixprotocol/contracts/FHE.sol";

contract FHEManagerTest is Test {
    using FHEManager for *;

    function testEncryptBasisPoints() public {
        uint32 threshold = 500; // 5%

        euint32 encrypted = FHEManager.encryptBasisPoints(threshold);

        // Verify encryption succeeded (non-zero handle)
        assertTrue(euint32.unwrap(encrypted) != 0, "Encryption failed");
    }

    function testEncryptBasisPoints_RevertsOnInvalid() public {
        uint32 invalidThreshold = 10001; // > 100%

        vm.expectRevert("FHEManager: Invalid basis points");
        FHEManager.encryptBasisPoints(invalidThreshold);
    }

    function testCompareThresholds_ExceedsThreshold() public {
        // Setup: threshold = 5% (500 bp)
        euint32 encryptedThreshold = FHEManager.encryptBasisPoints(500);

        // Current IL = 6% (600 bp) - exceeds threshold
        uint256 currentIL = 600;

        bool shouldExit = FHEManager.compareThresholds(
            currentIL,
            encryptedThreshold
        );

        assertTrue(shouldExit, "Should exit when IL exceeds threshold");
    }

    function testCompareThresholds_BelowThreshold() public {
        // Setup: threshold = 5% (500 bp)
        euint32 encryptedThreshold = FHEManager.encryptBasisPoints(500);

        // Current IL = 3% (300 bp) - below threshold
        uint256 currentIL = 300;

        bool shouldExit = FHEManager.compareThresholds(
            currentIL,
            encryptedThreshold
        );

        assertFalse(shouldExit, "Should not exit when IL below threshold");
    }

    function testCompareThresholds_EqualToThreshold() public {
        // Setup: threshold = 5% (500 bp)
        euint32 encryptedThreshold = FHEManager.encryptBasisPoints(500);

        // Current IL = 5% (500 bp) - equal to threshold
        uint256 currentIL = 500;

        bool shouldExit = FHEManager.compareThresholds(
            currentIL,
            encryptedThreshold
        );

        // Should not exit when equal (only exit when GREATER than)
        assertFalse(shouldExit, "Should not exit when IL equals threshold");
    }

    function testRequireThresholdBreached_Reverts() public {
        euint32 encryptedThreshold = FHEManager.encryptBasisPoints(500);
        uint256 currentIL = 300; // Below threshold

        vm.expectRevert(); // FHE.req should revert
        FHEManager.requireThresholdBreached(currentIL, encryptedThreshold);
    }

    function testRequireThresholdBreached_Succeeds() public {
        euint32 encryptedThreshold = FHEManager.encryptBasisPoints(500);
        uint256 currentIL = 600; // Above threshold

        // Should not revert
        FHEManager.requireThresholdBreached(currentIL, encryptedThreshold);
    }

    function testValidateEncryptedThreshold() public {
        euint32 validThreshold = FHEManager.encryptBasisPoints(500);
        
        bool isValid = FHEManager.validateEncryptedThreshold(validThreshold);
        
        assertTrue(isValid, "Valid threshold should pass validation");
    }

    function testEncryptPrice() public {
        uint256 price = 2500e18; // $2500

        euint256 encrypted = FHEManager.encryptPrice(price);

        assertTrue(euint256.unwrap(encrypted) != 0, "Price encryption failed");
    }

    function testComparePriceBounds_WithinBounds() public {
        // Setup price bounds: $2000 - $3000
        euint256 lowerBound = FHEManager.encryptPrice(2000e18);
        euint256 upperBound = FHEManager.encryptPrice(3000e18);

        // Current price: $2500 (within bounds)
        euint256 currentPrice = FHEManager.encryptPrice(2500e18);

        bool outOfBounds = FHEManager.comparePriceBounds(
            currentPrice,
            upperBound,
            lowerBound
        );

        assertFalse(outOfBounds, "Price should be within bounds");
    }

    function testComparePriceBounds_AboveUpper() public {
        euint256 lowerBound = FHEManager.encryptPrice(2000e18);
        euint256 upperBound = FHEManager.encryptPrice(3000e18);

        // Current price: $3500 (above upper)
        euint256 currentPrice = FHEManager.encryptPrice(3500e18);

        bool outOfBounds = FHEManager.comparePriceBounds(
            currentPrice,
            upperBound,
            lowerBound
        );

        assertTrue(outOfBounds, "Price should be out of bounds (above)");
    }

    function testComparePriceBounds_BelowLower() public {
        euint256 lowerBound = FHEManager.encryptPrice(2000e18);
        euint256 upperBound = FHEManager.encryptPrice(3000e18);

        // Current price: $1500 (below lower)
        euint256 currentPrice = FHEManager.encryptPrice(1500e18);

        bool outOfBounds = FHEManager.comparePriceBounds(
            currentPrice,
            upperBound,
            lowerBound
        );

        assertTrue(outOfBounds, "Price should be out of bounds (below)");
    }

    // P0 Enhancement Tests

    function testCompareThresholdsWithCache() public {
        FHEManager.FHECache storage cache;
        
        euint32 threshold = FHEManager.encryptBasisPoints(500);
        uint256 entryPrice = 2000e18;
        uint256 currentIL = 600;

        // First call - should cache
        bool shouldExit1 = FHEManager.compareThresholdsWithCache(
            currentIL,
            entryPrice,
            threshold,
            cache
        );

        assertTrue(shouldExit1, "Should exit on first call");

        // Second call with same entry price - should use cache
        bool shouldExit2 = FHEManager.compareThresholdsWithCache(
            currentIL,
            entryPrice,
            threshold,
            cache
        );

        assertTrue(shouldExit2, "Should exit on cached call");
    }
}
