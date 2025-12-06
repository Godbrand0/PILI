// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ILCalculator} from "../src/libraries/ILCalculator.sol";

/// @title ILCalculator Test Suite
/// @notice Comprehensive tests for IL calculation logic
contract ILCalculatorTest is Test {
    using ILCalculator for *;

    uint256 constant PRECISION = 1e18;
    uint256 constant BP_DIVISOR = 10000;

    function setUp() public {
        // Setup if needed
    }

    /*//////////////////////////////////////////////////////////////
                           UNIT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_calculateIL_NoPriceChange() public {
        uint256 entryPrice = 2000 * PRECISION; // $2000
        uint256 currentPrice = 2000 * PRECISION; // $2000
        
        uint256 il = ILCalculator.calculateIL(entryPrice, currentPrice);
        
        assertEq(il, 0, "IL should be 0 when price unchanged");
    }

    function test_calculateIL_PriceDoubles() public {
        uint256 entryPrice = 1000 * PRECISION; // $1000
        uint256 currentPrice = 2000 * PRECISION; // $2000
        
        uint256 il = ILCalculator.calculateIL(entryPrice, currentPrice);
        
        // When price 2x, IL ≈ 5.72%
        assertApproxEqAbs(il, 572, 10, "IL should be ~5.72% when price doubles");
    }

    function test_calculateIL_PriceHalves() public {
        uint256 entryPrice = 2000 * PRECISION; // $2000
        uint256 currentPrice = 1000 * PRECISION; // $1000
        
        uint256 il = ILCalculator.calculateIL(entryPrice, currentPrice);
        
        // When price 0.5x, IL ≈ 5.72%
        assertApproxEqAbs(il, 572, 10, "IL should be ~5.72% when price halves");
    }

    function test_calculateIL_Price4x() public {
        uint256 entryPrice = 1000 * PRECISION;
        uint256 currentPrice = 4000 * PRECISION;
        
        uint256 il = ILCalculator.calculateIL(entryPrice, currentPrice);
        
        // When price 4x, IL ≈ 20%
        assertApproxEqAbs(il, 2000, 50, "IL should be ~20% when price 4x");
    }

    function test_calculateIL_revertsOnZeroEntryPrice() public {
        vm.expectRevert(ILCalculator.InvalidEntryPrice.selector);
        ILCalculator.calculateIL(0, 2000 * PRECISION);
    }

    function test_calculateIL_revertsOnZeroCurrentPrice() public {
        vm.expectRevert(ILCalculator.InvalidCurrentPrice.selector);
        ILCalculator.calculateIL(2000 * PRECISION, 0);
    }

    function test_sqrt_BasicCases() public {
        assertEq(ILCalculator.sqrt(0), 0);
        assertEq(ILCalculator.sqrt(1), 1);
        assertEq(ILCalculator.sqrt(4), 2);
        assertEq(ILCalculator.sqrt(9), 3);
        assertEq(ILCalculator.sqrt(16), 4);
        assertEq(ILCalculator.sqrt(100), 10);
    }

    function test_sqrt_LargeNumbers() public {
        uint256 result = ILCalculator.sqrt(1e36);
        assertEq(result, 1e18, "sqrt(1e36) should equal 1e18");
    }

    function test_validateILThreshold_ValidRanges() public {
        assertTrue(ILCalculator.validateILThreshold(10));   // 0.1%
        assertTrue(ILCalculator.validateILThreshold(500));  // 5%
        assertTrue(ILCalculator.validateILThreshold(1000)); // 10%
        assertTrue(ILCalculator.validateILThreshold(5000)); // 50%
    }

    function test_validateILThreshold_InvalidRanges() public {
        assertFalse(ILCalculator.validateILThreshold(0));     // Too small
        assertFalse(ILCalculator.validateILThreshold(5));     // Too small
        assertFalse(ILCalculator.validateILThreshold(5001));  // Too large
        assertFalse(ILCalculator.validateILThreshold(10000)); // Too large
    }

    function test_priceChangePercent_Increase() public {
        uint256 oldPrice = 1000 * PRECISION;
        uint256 newPrice = 1500 * PRECISION;
        
        int256 change = ILCalculator.priceChangePercent(oldPrice, newPrice);
        
        assertEq(change, 5000, "50% price increase should return 5000 bp");
    }

    function test_priceChangePercent_Decrease() public {
        uint256 oldPrice = 2000 * PRECISION;
        uint256 newPrice = 1000 * PRECISION;
        
        int256 change = ILCalculator.priceChangePercent(oldPrice, newPrice);
        
        assertEq(change, -5000, "50% price decrease should return -5000 bp");
    }

    /*//////////////////////////////////////////////////////////////
                           FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_calculateIL_NeverNegative(uint256 entryPrice, uint256 currentPrice) public {
        entryPrice = bound(entryPrice, 1, 1e30);
        currentPrice = bound(currentPrice, 1, 1e30);
        
        // Test with bounded inputs to avoid extreme price ratios
        if (currentPrice > entryPrice * 1000 || entryPrice > currentPrice * 1000) {
            return; // Skip extreme ratios
        }
        
        uint256 il = ILCalculator.calculateIL(entryPrice, currentPrice);
        assertGe(il, 0, "IL should never be negative");
    }

    function testFuzz_sqrt_AlwaysCorrect(uint256 x) public {
        x = bound(x, 0, type(uint128).max);
        
        uint256 result = ILCalculator.sqrt(x);
        uint256 squared = result * result;
        uint256 nextSquared = (result + 1) * (result + 1);
        
        assertGe(squared, 0);
        assertLe(squared, x, "sqrt squared should be <= original");
        assertGt(nextSquared, x, "next integer squared should be > original");
    }

    /*//////////////////////////////////////////////////////////////
                        INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_calculatePositionValue_NoIL() public {
        uint256 token0 = 10 ether;
        uint256 token1 = 20000 ether; // Entry price: 2000
        uint256 currentPrice = 2000 * PRECISION;
        
        (uint256 hodlValue, uint256 lpValue, uint256 il) = 
            ILCalculator.calculatePositionValue(token0, token1, currentPrice);
        
        assertEq(hodlValue, lpValue, "Values should match at same price");
        assertEq(il, 0, "IL should be 0");
    }

    function test_sqrtPriceX96ToPrice_Conversion() public {
        // sqrtPriceX96 for price = 1 (1:1 ratio)
        uint160 sqrtPriceX96 = uint160(1 << 96);
        
        uint256 price = ILCalculator.sqrtPriceX96ToPrice(sqrtPriceX96);
        
        assertEq(price, PRECISION, "Price should be 1e18 for 1:1 ratio");
    }

    /*//////////////////////////////////////////////////////////////
                        GAS BENCHMARKS
    //////////////////////////////////////////////////////////////*/

    function test_gas_calculateIL() public {
        uint256 entryPrice = 2000 * PRECISION;
        uint256 currentPrice = 2500 * PRECISION;
        
        uint256 gasBefore = gasleft();
        ILCalculator.calculateIL(entryPrice, currentPrice);
        uint256 gasUsed = gasBefore - gasleft();
        
        console.log("Gas used for calculateIL:", gasUsed);
        assertLt(gasUsed, 10000, "calculateIL should use < 10k gas");
    }

    function test_gas_sqrt() public {
        uint256 gasBefore = gasleft();
        ILCalculator.sqrt(1e36);
        uint256 gasUsed = gasBefore - gasleft();
        
        console.log("Gas used for sqrt:", gasUsed);
        assertLt(gasUsed, 5000, "sqrt should use < 5k gas");
    }
}
