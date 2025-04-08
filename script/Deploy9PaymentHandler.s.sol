// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PaymentRequestHandler} from "../src/handlers/payment/PaymentRequestHandler.sol";

contract DeployHandlersScript is Script {
    address public constant OWNER_ADDRESS = 0x51B89C499F3038756Eff64a0EF52d753147EAd75;

    address public constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    address public constant ORDER_EXECUTOR = 0x06145CfE8bCEE920088bfe240817b6C9473C9cf3;

    function run() public {
        vm.startBroadcast();

        PaymentRequestHandler paymentRequestHandler =
            new PaymentRequestHandler{salt: keccak256("Ver3")}(PERMIT2_ADDRESS, msg.sender);

        paymentRequestHandler.setOrderExecutor(ORDER_EXECUTOR);

        paymentRequestHandler.transferOwnership(OWNER_ADDRESS);

        console.log("PaymentRequestHandler deployed at", address(paymentRequestHandler));

        vm.stopBroadcast();
    }
}
