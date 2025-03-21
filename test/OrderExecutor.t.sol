// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {OrderExecutor} from "../src/OrderExecutor.sol";
import {TransferOrder} from "../src/TransferOrder.sol";


contract OrderExecutorTest is Test {
    OrderExecutor public orderExecutor;
    TransferOrder public transferOrder;

    function setUp() public {
        orderExecutor = new OrderExecutor(address(0));
        transferOrder = new TransferOrder();
    }

    function test_Execute() public {
        orderExecutor.execute(address(transferOrder), bytes(""), bytes(""), bytes(""));
    }
}
