// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {OrderExecutor} from "../src/OrderExecutor.sol";

contract OrderExecutorScript is Script {
    OrderExecutor public orderExecutor;

    address public constant OWNER_ADDRESS = 0x51B89C499F3038756Eff64a0EF52d753147EAd75;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        orderExecutor = new OrderExecutor(address(0), OWNER_ADDRESS);

        vm.stopBroadcast();
    }
}
