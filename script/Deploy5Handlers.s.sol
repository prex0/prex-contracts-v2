// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {LinkTransferHandler} from "../src/handlers/link-transfer/LinkTransferHandler.sol";
import {TransferRequestHandler} from "../src/handlers/transfer/TransferRequestHandler.sol";

contract DeployHandlersScript is Script {
    address public constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    function run() public {
        vm.startBroadcast();

        LinkTransferHandler linkTransferHandler =
            new LinkTransferHandler{salt: keccak256("LinkTransferHandler3")}(PERMIT2_ADDRESS);

        console.log("LinkTransferHandler deployed at", address(linkTransferHandler));

        TransferRequestHandler transferRequestHandler =
            new TransferRequestHandler{salt: keccak256("TransferRequestHandler3")}(PERMIT2_ADDRESS);

        console.log("TransferRequestHandler deployed at", address(transferRequestHandler));

        vm.stopBroadcast();
    }
}
