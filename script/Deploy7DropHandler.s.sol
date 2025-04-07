// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DropHandler} from "../src/handlers/drop/DropHandler.sol";

contract DeployDropHandlerScript is Script {
    address public constant OWNER_ADDRESS = 0x51B89C499F3038756Eff64a0EF52d753147EAd75;

    address public constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    address public constant ORDER_EXECUTOR = 0x1e2F0cF2f6E51103075fA6beB605bA5C898c5e2B;

    function run() public {
        vm.startBroadcast();

        DropHandler dropHandler = new DropHandler{salt: keccak256("DropHandler3")}(PERMIT2_ADDRESS, msg.sender);

        dropHandler.setOrderExecutor(ORDER_EXECUTOR);

        dropHandler.transferOwnership(OWNER_ADDRESS);

        console.log("DropHandler deployed at", address(dropHandler));

        vm.stopBroadcast();
    }
}
