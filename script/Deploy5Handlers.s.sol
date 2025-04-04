// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DropHandler} from "../src/handlers/drop/DropHandler.sol";
import {LinkTransferHandler} from "../src/handlers/link-transfer/LinkTransferHandler.sol";
import {LotteryHandler} from "../src/handlers/lottery/LotteryHandler.sol";
import {PaymentRequestHandler} from "../src/handlers/payment/PaymentRequestHandler.sol";
import {TransferRequestHandler} from "../src/handlers/transfer/TransferRequestHandler.sol";

contract DeployHandlersScript is Script {
    address public constant OWNER_ADDRESS = 0x51B89C499F3038756Eff64a0EF52d753147EAd75;

    address public constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    address public constant ORDER_EXECUTOR = 0x4fF089348469DA4543e8935A6AF0C362Cb27c0BD;

    function run() public {
        vm.startBroadcast();

        DropHandler dropHandler = new DropHandler{salt: keccak256("DropHandler3")}(PERMIT2_ADDRESS, msg.sender);

        dropHandler.setOrderExecutor(ORDER_EXECUTOR);

        dropHandler.transferOwnership(OWNER_ADDRESS);

        console.log("DropHandler deployed at", address(dropHandler));

        LinkTransferHandler linkTransferHandler =
            new LinkTransferHandler{salt: keccak256("LinkTransferHandler3")}(PERMIT2_ADDRESS);

        console.log("LinkTransferHandler deployed at", address(linkTransferHandler));

        LotteryHandler lotteryHandler = new LotteryHandler{salt: keccak256("LotteryHandler3")}(PERMIT2_ADDRESS);

        console.log("LotteryHandler deployed at", address(lotteryHandler));

        PaymentRequestHandler paymentRequestHandler =
            new PaymentRequestHandler{salt: keccak256("PaymentRequestHandler3")}(PERMIT2_ADDRESS);

        console.log("PaymentRequestHandler deployed at", address(paymentRequestHandler));

        TransferRequestHandler transferRequestHandler =
            new TransferRequestHandler{salt: keccak256("TransferRequestHandler3")}(PERMIT2_ADDRESS);

        console.log("TransferRequestHandler deployed at", address(transferRequestHandler));

        vm.stopBroadcast();
    }
}
