// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract UtilsTest is Test {
    function test_sqrtPriceX96() public {
        console.log(uint256(uint256(2 ** 192) / uint256(6892168815194673229586)));
    }
}
