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
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {FHEManager} from "../src/libraries/FHEManager.sol";
import {euint32} from "../src/interfaces/ILPPosition.sol";

/// @title FHEManager Test Suite
/// @notice Tests for FHE operations stub
contract FHEManagerTest is Test {
    
    function setUp() public {}

    function test_encryptBasisPoints_ValidRange() public {
        euint32 encrypted = FHEManager.encryptBasisPoints(500);
        assertGt(euint32.unwrap(encrypted), 0, "Encrypted value should be non-zero");
    }

    function test_encryptBasisPoints_revertsOnInvalidBasisPoints() public {
        vm.expectRevert(FHEManager.InvalidBasisPoints.selector);
        FHEManager.encryptBasisPoints(10001);
    }

    function test_compareThresholds_BelowThreshold() public {
        euint32 threshold = FHEManager.encryptBasisPoints(500); // 5%
        bool shouldExit = FHEManager.compareThresholds(300, threshold); // 3%
        
        assertFalse(shouldExit, "Should not exit when below threshold");
    }

    function test_compareThresholds_AboveThreshold() public {
        euint32 threshold = FHEManager.encryptBasisPoints(500); // 5%
        bool shouldExit = FHEManager.compareThresholds(700, threshold); // 7%
        
        assertTrue(shouldExit, "Should exit when above threshold");
    }

    function test_compareThresholds_ExactThreshold() public {
        euint32 threshold = FHEManager.encryptBasisPoints(500);
        bool shouldExit = FHEManager.compareThresholds(500, threshold);
        
        assertFalse(shouldExit, "Should not exit at exact threshold");
    }

    function test_validateEncryptedThreshold_Valid() public {
        euint32 threshold = FHEManager.encryptBasisPoints(500);
        bool isValid = FHEManager.validateEncryptedThreshold(threshold);
        
        assertTrue(isValid, "Valid threshold should pass validation");
    }

    function test_validateEncryptedThreshold_TooLow() public {
        euint32 threshold = euint32.wrap(5); // 0.05% - below minimum
        bool isValid = FHEManager.validateEncryptedThreshold(threshold);
        
        assertFalse(isValid, "Threshold below 0.1% should be invalid");
    }

    function test_validateEncryptedThreshold_TooHigh() public {
        euint32 threshold = euint32.wrap(6000); // 60% - above maximum
        bool isValid = FHEManager.validateEncryptedThreshold(threshold);
        
        assertFalse(isValid, "Threshold above 50% should be invalid");
    }

    function test_validateEncryptedThreshold_Zero() public {
        euint32 threshold = euint32.wrap(0);
        bool isValid = FHEManager.validateEncryptedThreshold(threshold);
        
        assertFalse(isValid, "Zero threshold should be invalid");
    }

    function test_decryptValue_RoundTrip() public {
        uint32 original = 500;
        euint32 encrypted = FHEManager.encryptBasisPoints(original);
        uint32 decrypted = FHEManager.decryptValue(encrypted);
        
        assertEq(decrypted, original, "Decrypt should return original value");
    }

    function test_estimateFHEGasCost() public {
        uint256 estimatedGas = FHEManager.estimateFHEGasCost();
        
        assertEq(estimatedGas, 170000, "Total FHE gas should be 170k");
    }

    function test_isFHEAvailable() public {
        bool available = FHEManager.isFHEAvailable();
        assertTrue(available, "FHE should be available in stub");
    }

    function test_requireThresholdBreached_Passes() public {
        euint32 threshold = FHEManager.encryptBasisPoints(500);
        
        // Should not revert when IL > threshold
        FHEManager.requireThresholdBreached(600, threshold);
    }

    function test_requireThresholdBreached_Reverts() public {
        euint32 threshold = FHEManager.encryptBasisPoints(500);
        
        vm.expectRevert(FHEManager.FHEComparisonFailed.selector);
        FHEManager.requireThresholdBreached(400, threshold);
    }

    /*//////////////////////////////////////////////////////////////
                           FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_encryptBasisPoints_ValidInputs(uint32 basisPoints) public {
        basisPoints = uint32(bound(basisPoints, 0, 10000));
        
        if (basisPoints > 10000) {
            return; // Skip invalid inputs
        }
        
        euint32 encrypted = FHEManager.encryptBasisPoints(basisPoints);
        assertGt(euint32.unwrap(encrypted), 0);
    }

    function testFuzz_compareThresholds_Consistency(uint256 currentIL, uint32 thresholdBp) public {
        currentIL = bound(currentIL, 0, 10000);
        thresholdBp = uint32(bound(thresholdBp, 10, 5000));
        
        euint32 threshold = FHEManager.encryptBasisPoints(thresholdBp);
        bool shouldExit = FHEManager.compareThresholds(currentIL, threshold);
        
        if (currentIL > thresholdBp) {
            assertTrue(shouldExit, "Should exit when IL exceeds threshold");
        } else {
            assertFalse(shouldExit, "Should not exit when IL below/equal threshold");
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GAS BENCHMARKS
    //////////////////////////////////////////////////////////////*/

    function test_gas_encryptBasisPoints() public {
        uint256 gasBefore = gasleft();
        FHEManager.encryptBasisPoints(500);
        uint256 gasUsed = gasBefore - gasleft();
        
        console.log("Gas used for encryptBasisPoints:", gasUsed);
    }

    function test_gas_compareThresholds() public {
        euint32 threshold = FHEManager.encryptBasisPoints(500);
        
        uint256 gasBefore = gasleft();
        FHEManager.compareThresholds(600, threshold);
        uint256 gasUsed = gasBefore - gasleft();
        
        console.log("Gas used for compareThresholds:", gasUsed);
    }
}
