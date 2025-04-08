// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {LotteryHandler} from "../src/handlers/lottery/LotteryHandler.sol";

contract DeployHandlersScript is Script {
    address public constant OWNER_ADDRESS = 0x51B89C499F3038756Eff64a0EF52d753147EAd75;

    address public constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    address public constant ORDER_EXECUTOR = 0x06145CfE8bCEE920088bfe240817b6C9473C9cf3;

    function run() public {
        vm.startBroadcast();

        LotteryHandler lotteryHandler =
            new LotteryHandler{salt: keccak256("Ver3")}(PERMIT2_ADDRESS, msg.sender);

        lotteryHandler.setOrderExecutor(ORDER_EXECUTOR);

        lotteryHandler.transferOwnership(OWNER_ADDRESS);

        console.log("LotteryHandler deployed at", address(lotteryHandler));

        vm.stopBroadcast();
    }
}
