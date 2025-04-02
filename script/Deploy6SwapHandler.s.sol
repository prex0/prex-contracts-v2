// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SwapHandler} from "../src/handlers/swap/SwapHandler.sol";

contract Deploy6SwapHandlerScript is Script {
    address public constant OWNER_ADDRESS = 0x51B89C499F3038756Eff64a0EF52d753147EAd75;

    address public constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    address public constant UNIVERSAL_ROUTER = 0x851116D9223fabED8E56C0E6b8Ad0c31d98B3507;

    address public constant LOYALTY_CONVERTER = 0x3F7f8c8c233f483D0A7d37168350e3aDB870F893;

    address public constant PUM_CONVERTER = 0xd9545656d7D36d61B3f31580d9eDC5EC53B6f2Bc;

    function run() public {
        vm.startBroadcast();

        SwapHandler swapHandler = new SwapHandler{salt: keccak256("SwapHandler")}(
            UNIVERSAL_ROUTER, LOYALTY_CONVERTER, PUM_CONVERTER, PERMIT2_ADDRESS, OWNER_ADDRESS
        );

        console.log("SwapHandler deployed at", address(swapHandler));

        vm.stopBroadcast();
    }
}
