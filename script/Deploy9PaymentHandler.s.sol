// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PaymentRequestHandler} from "../src/handlers/payment/PaymentRequestHandler.sol";

contract DeployHandlersScript is Script {
    address public constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    function run() public {
        vm.startBroadcast();

        PaymentRequestHandler paymentRequestHandler =
            new PaymentRequestHandler{salt: keccak256("PaymentRequestHandler3")}(PERMIT2_ADDRESS);

        console.log("PaymentRequestHandler deployed at", address(paymentRequestHandler));

        vm.stopBroadcast();
    }
}
