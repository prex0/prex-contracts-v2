// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {OrderExecutor} from "../src/OrderExecutor.sol";

contract OrderExecutorScript is Script {
    OrderExecutor public orderExecutor;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        orderExecutor = new OrderExecutor(address(0));

        vm.stopBroadcast();
    }
}
