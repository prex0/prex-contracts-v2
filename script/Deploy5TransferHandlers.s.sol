// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {LinkTransferHandler} from "../src/handlers/link-transfer/LinkTransferHandler.sol";
import {TransferRequestHandler} from "../src/handlers/transfer/TransferRequestHandler.sol";

contract DeployTransferHandlersScript is Script {
    address public constant OWNER_ADDRESS = 0x51B89C499F3038756Eff64a0EF52d753147EAd75;

    address public constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    address public constant ORDER_EXECUTOR = 0x06145CfE8bCEE920088bfe240817b6C9473C9cf3;

    function run() public {
        vm.startBroadcast();

        LinkTransferHandler linkTransferHandler =
            new LinkTransferHandler{salt: keccak256("Ver3")}(PERMIT2_ADDRESS, msg.sender);

        linkTransferHandler.setOrderExecutor(ORDER_EXECUTOR);

        linkTransferHandler.transferOwnership(OWNER_ADDRESS);

        console.log("LinkTransferHandler deployed at", address(linkTransferHandler));

        TransferRequestHandler transferRequestHandler =
            new TransferRequestHandler{salt: keccak256("Ver3")}(PERMIT2_ADDRESS, msg.sender);

        transferRequestHandler.setOrderExecutor(ORDER_EXECUTOR);

        transferRequestHandler.transferOwnership(OWNER_ADDRESS);

        console.log("TransferRequestHandler deployed at", address(transferRequestHandler));

        vm.stopBroadcast();
    }
}
