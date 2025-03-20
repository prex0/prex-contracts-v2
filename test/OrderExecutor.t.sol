// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {OrderExecutor} from "../src/OrderExecutor.sol";

contract OrderExecutorTest is Test {
    OrderExecutor public orderExecutor;

    function setUp() public {
        orderExecutor = new OrderExecutor(address(0));
    }

    function test_Execute() public {
        orderExecutor.execute(address(0), bytes(""), bytes(""), bytes(""));
    }
}
