// SPDX-License-Identifier: MIT
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
