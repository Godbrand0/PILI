// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/libraries/ILCalculator.sol";
import {FullMath} from "v4-core/libraries/FullMath.sol";

contract ILCalculatorTest is Test {
    using ILCalculator for *;

    uint256 constant PRECISION = 1e18;

    function toSqrtPriceX96(uint256 price) internal pure returns (uint160) {
        // sqrtPriceX96 = sqrt(price) * 2^96
        // Use 1e18 precision for sqrt calculation to reduce error
        uint256 sqrtP = ILCalculator.sqrt(price * 1e18);
        // sqrtP is sqrt(price) * 1e9
        // We want sqrt(price) * 2^96
        // So (sqrtP / 1e9) * 2^96
        // Use FullMath to avoid overflow
        return uint160(FullMath.mulDiv(sqrtP, 1 << 96, 1e9));
    }

    function testCalculateIL_PriceDoubles() public {
        uint256 entryPrice = toSqrtPriceX96(2000); // $2000
        uint256 currentPrice = toSqrtPriceX96(4000); // $4000

        uint256 ilBp = ILCalculator.calculateIL(entryPrice, currentPrice);

        // When price doubles, IL should be ~5.72%
        // 5.72% = 572 basis points
        assertApproxEqAbs(ilBp, 572, 10); // Allow 10 bp tolerance
    }

    function testCalculateIL_PriceUnchanged() public {
        uint256 entryPrice = toSqrtPriceX96(2000);
        uint256 currentPrice = toSqrtPriceX96(2000);

        uint256 ilBp = ILCalculator.calculateIL(entryPrice, currentPrice);

        // No price change = no IL
        assertEq(ilBp, 0);
    }

    function testCalculateIL_SmallPriceIncrease() public {
        uint256 entryPrice = toSqrtPriceX96(2000);
        uint256 currentPrice = toSqrtPriceX96(2100); // 5% increase

        uint256 ilBp = ILCalculator.calculateIL(entryPrice, currentPrice);

        // Small price change = small IL
        // IL formula for 5% price change is approx 0.03% = 3 bps
        assertApproxEqAbs(ilBp, 3, 1);
    }

    function testCalculateIL_PriceHalves() public {
        uint256 entryPrice = toSqrtPriceX96(2000);
        uint256 currentPrice = toSqrtPriceX96(1000);

        uint256 ilBp = ILCalculator.calculateIL(entryPrice, currentPrice);

        // Same IL as doubling: ~5.72%
        assertApproxEqAbs(ilBp, 572, 10);
    }

    function testCalculateIL_PriceCrash90Percent() public {
        uint256 entryPrice = toSqrtPriceX96(1000);
        uint256 currentPrice = toSqrtPriceX96(100); // 90% drop

        uint256 ilBp = ILCalculator.calculateIL(entryPrice, currentPrice);

        // Price ratio = 0.1
        // IL = 2 * sqrt(0.1) / (1 + 0.1) - 1
        // IL = 2 * 0.3162 / 1.1 - 1
        // IL = 0.6324 / 1.1 - 1
        // IL = 0.5749 - 1 = -0.4251
        // IL % = 42.51%
        // IL BP = 4251
        assertApproxEqAbs(ilBp, 4251, 20);
    }

    function testCalculatePositionValue() public {
        uint256 token0Amount = 10 * PRECISION; // 10 ETH
        uint256 token1Amount = 20000 * PRECISION; // 20,000 USDC
        uint256 currentPrice = 4000 * PRECISION; // Price doubles

        (uint256 hodlValue, uint256 lpValue, uint256 ilBp) = ILCalculator.calculatePositionValue(
            token0Amount,
            token1Amount,
            currentPrice
        );

        // HODL: 10 ETH * $4000 + $20,000 = $60,000
        assertEq(hodlValue, 60000 * PRECISION);

        // LP value should be less due to IL
        assertLt(lpValue, hodlValue);
        
        // IL should be consistent
        assertApproxEqAbs(ilBp, 572, 10);
    }

    function testSqrt() public {
        assertEq(ILCalculator.sqrt(0), 0);
        assertEq(ILCalculator.sqrt(1), 1);
        assertEq(ILCalculator.sqrt(4), 2);
        assertEq(ILCalculator.sqrt(9), 3);
        assertEq(ILCalculator.sqrt(16), 4);
        assertEq(ILCalculator.sqrt(25), 5);
        assertEq(ILCalculator.sqrt(100), 10);
        assertEq(ILCalculator.sqrt(2), 1); // Integer truncation
    }

    // Wrapper functions to test library reverts
    function calculateILWrapper(uint256 entryPrice, uint256 currentPrice) public pure {
        ILCalculator.calculateIL(entryPrice, currentPrice);
    }

    function calculatePositionValueWrapper(uint256 token0, uint256 token1, uint256 price) public pure {
        ILCalculator.calculatePositionValue(token0, token1, price);
    }

    function testCalculateIL_RevertIfPriceIsZero() public {
        vm.expectRevert(ILCalculator.InvalidEntryPrice.selector);
        this.calculateILWrapper(0, 100);

        vm.expectRevert(ILCalculator.InvalidCurrentPrice.selector);
        this.calculateILWrapper(100, 0);
    }

    function testCalculateIL_RevertIfPriceRatioTooLarge() public {
        uint256 entryPrice = toSqrtPriceX96(1);
        uint256 currentPrice = toSqrtPriceX96(2000); // 2000x > 1000x limit

        vm.expectRevert(ILCalculator.PriceRatioTooLarge.selector);
        this.calculateILWrapper(entryPrice, currentPrice);
    }

    function testCalculatePositionValue_RevertIfPriceIsZero() public {
        vm.expectRevert(ILCalculator.InvalidCurrentPrice.selector);
        this.calculatePositionValueWrapper(100, 100, 0);
    }
}
