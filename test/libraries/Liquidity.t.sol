// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {LiquidityAmounts} from "../../lib/v4-periphery/src/libraries/LiquidityAmounts.sol";
import {TickMath} from "../../lib/v4-periphery/lib/v4-core/src/libraries/TickMath.sol";
import {FullMath} from "../../lib/v4-periphery/lib/v4-core/src/libraries/FullMath.sol";

contract LiquidityTest is Test {
    function test_getLiquidityForAmount0() public pure {
        uint160 sqrtPrice1A = TickMath.getSqrtPriceAtTick(-340800);
        uint160 sqrtPrice1B = TickMath.getSqrtPriceAtTick(887100);
        uint160 sqrtPrice2A = TickMath.getSqrtPriceAtTick(-887100);
        uint160 sqrtPrice2B = TickMath.getSqrtPriceAtTick(340800);

        assertEq(LiquidityAmounts.getLiquidityForAmount0(sqrtPrice1A, sqrtPrice1B, 1e8 * 1e18), 3980998579334402966);
        assertEq(LiquidityAmounts.getLiquidityForAmount0(sqrtPrice2A, sqrtPrice2B, 1e8 * 1e18), 5468035);
        assertEq(LiquidityAmounts.getLiquidityForAmount1(sqrtPrice1A, sqrtPrice1B, 1e8 * 1e18), 5468035);
        assertEq(LiquidityAmounts.getLiquidityForAmount1(sqrtPrice2A, sqrtPrice2B, 1e8 * 1e18), 3980998579334402966);
    }

    function test_ticks() public pure {
        assertEq(TickMath.getSqrtPriceAtTick(-340800), 3154072024125615277578);
        assertEq(TickMath.getSqrtPriceAtTick(887100), 1448932774539288529081579456328344892474222954692);
        assertEq(TickMath.getSqrtPriceAtTick(-887100), 4332224273);
        assertEq(TickMath.getSqrtPriceAtTick(340800), 1990158020290245125897017643766414215);
    }

    function test_price() public pure {
        uint160 sqrtPrice1A = 7086382300000000000000;

        uint256 price = FullMath.mulDiv(sqrtPrice1A, sqrtPrice1A, 2 ** 96);
        uint256 price2 = FullMath.mulDiv(price, 1e18 * 1000000, 2 ** 96);

        assertEq(price2 / 200, 40000000);
    }

    function test_inverse_price() public pure {
        uint160 sqrtPrice1A = 7086382300000000000000;

        uint256 sqrtPriceB = FullMath.mulDiv(2 ** 96, 2 ** 96, sqrtPrice1A);

        assertEq(sqrtPriceB, 885797783642957107159712428047759491);
    }

    function test_price2() public pure {
        uint160 sqrtPrice1A = 885797783642957107159712428047759491;

        uint256 price = FullMath.mulDiv(sqrtPrice1A, sqrtPrice1A, 2 ** 96);
        uint256 price2 = FullMath.mulDiv(price, 1e6, 2 ** 96);

        assertEq(price2 * 200, 24999999891142116539600);

        //        assertEq(price * 1e6 / 2**96, 1e18);
    }
}
