// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {OrderExecutor} from "../src/OrderExecutor.sol";
import {BuyPrexPointHandler} from "../src/handlers/point/BuyPrexPointHandler.sol";

contract OrderExecutorScript is Script {
    OrderExecutor public orderExecutor;

    address public constant OWNER_ADDRESS = 0x51B89C499F3038756Eff64a0EF52d753147EAd75;

    address public constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        BuyPrexPointHandler pointHandler = new BuyPrexPointHandler{salt: keccak256("BuyPrexPointHandler")}(
            OWNER_ADDRESS, PERMIT2_ADDRESS, OWNER_ADDRESS
        );

        orderExecutor =
            new OrderExecutor{salt: keccak256("OrderExecutor")}(address(pointHandler.point()), msg.sender);
        orderExecutor.addHandler(address(pointHandler));

        orderExecutor.transferOwnership(OWNER_ADDRESS);

        console.log("OrderExecutor deployed at", address(orderExecutor));
        console.log("BuyPrexPointHandler deployed at", address(pointHandler));

        vm.stopBroadcast();
    }
}
