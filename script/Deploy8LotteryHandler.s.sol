// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {LotteryHandler} from "../src/handlers/lottery/LotteryHandler.sol";

contract DeployHandlersScript is Script {
    address public constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    function run() public {
        vm.startBroadcast();

        LotteryHandler lotteryHandler = new LotteryHandler{salt: keccak256("LotteryHandler3")}(PERMIT2_ADDRESS);

        console.log("LotteryHandler deployed at", address(lotteryHandler));

        vm.stopBroadcast();
    }
}
