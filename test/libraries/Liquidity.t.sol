// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {LiquidityAmounts} from "../../lib/v4-periphery/src/libraries/LiquidityAmounts.sol";
import {TickMath} from "../../lib/v4-periphery/lib/v4-core/src/libraries/TickMath.sol";
import {FullMath} from "../../lib/v4-periphery/lib/v4-core/src/libraries/FullMath.sol";

contract LiquidityTest is Test {
    function test_CalculateLiquidity() public pure {
        uint160 sqrtPrice1A = TickMath.getSqrtPriceAtTick(-340500);
        uint160 sqrtPrice1B = TickMath.getSqrtPriceAtTick(887100);
        uint160 sqrtPrice2A = TickMath.getSqrtPriceAtTick(-887100);
        uint160 sqrtPrice2B = TickMath.getSqrtPriceAtTick(340500);

        assertEq(
            LiquidityAmounts.getLiquidityForAmount0(sqrtPrice1A, sqrtPrice1B, 8 * 1e8 * 1e18), 32329285099435181112
        );
        assertEq(LiquidityAmounts.getLiquidityForAmount0(sqrtPrice2A, sqrtPrice2B, 8 * 1e8 * 1e18), 43744286);
        assertEq(LiquidityAmounts.getLiquidityForAmount1(sqrtPrice1A, sqrtPrice1B, 8 * 1e8 * 1e18), 43744286);
        assertEq(
            LiquidityAmounts.getLiquidityForAmount1(sqrtPrice2A, sqrtPrice2B, 8 * 1e8 * 1e18), 32329285099435181112
        );
    }

    function test_CalculateLiquidity2() public pure {
        uint160 sqrtPrice1A = TickMath.getSqrtPriceAtTick(-370800);
        uint160 sqrtPrice1B = TickMath.getSqrtPriceAtTick(887100);
        uint160 sqrtPrice2A = TickMath.getSqrtPriceAtTick(-887100);
        uint160 sqrtPrice2B = TickMath.getSqrtPriceAtTick(370800);

        assertEq(LiquidityAmounts.getLiquidityForAmount0(sqrtPrice1A, sqrtPrice1B, 2 * 1e8 * 1e18), 1776694939356593754);
        assertEq(LiquidityAmounts.getLiquidityForAmount0(sqrtPrice2A, sqrtPrice2B, 2 * 1e8 * 1e18), 10936071);
        assertEq(LiquidityAmounts.getLiquidityForAmount1(sqrtPrice1A, sqrtPrice1B, 2 * 1e8 * 1e18), 10936071);
        assertEq(LiquidityAmounts.getLiquidityForAmount1(sqrtPrice2A, sqrtPrice2B, 2 * 1e8 * 1e18), 1776694939356593754);
    }

    function test_ticks() public pure {
        assertEq(TickMath.getSqrtPriceAtTick(-370800), 703821376968076159065);
        assertEq(TickMath.getSqrtPriceAtTick(370800), 8918600572246325433610950567317619554);

        assertEq(TickMath.getSqrtPriceAtTick(-340500), 3201737317285043780301);
        assertEq(TickMath.getSqrtPriceAtTick(887100), 1448932774539288529081579456328344892474222954692);
        assertEq(TickMath.getSqrtPriceAtTick(-887100), 4332224273);
        assertEq(TickMath.getSqrtPriceAtTick(340500), 1960529897783567580031827502804107061);
    }

    function test_price() public pure {
        uint160 sqrtPrice1A = 3543191200000000000000;

        uint256 price = FullMath.mulDiv(sqrtPrice1A, sqrtPrice1A, 2 ** 96);
        uint256 price2 = FullMath.mulDiv(price, 1e18 * 1000000, 2 ** 96);

        assertEq(price2 / 200, 10000000);
    }

    function test_inverse_price() public pure {
        uint160 sqrtPrice1A = 3543191200000000000000;

        uint256 sqrtPriceB = FullMath.mulDiv(2 ** 96, 2 ** 96, sqrtPrice1A);

        assertEq(sqrtPriceB, 1771595542285914675966622806922659555);
    }

    function test_price2() public pure {
        uint160 sqrtPrice1A = 1771595542285914675966622806922659555;

        uint256 price = FullMath.mulDiv(sqrtPrice1A, sqrtPrice1A, 2 ** 96);
        uint256 price2 = FullMath.mulDiv(price, 1e6, 2 ** 96);

        assertEq(price2 * 200, 99999996742253970147800);

        //        assertEq(price * 1e6 / 2**96, 1e18);
    }
}
