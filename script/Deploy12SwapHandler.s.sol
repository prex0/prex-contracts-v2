// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SwapHandler} from "../src/handlers/swap/SwapHandler.sol";

contract Deploy6SwapHandlerScript is Script {
    address public constant OWNER_ADDRESS = 0x51B89C499F3038756Eff64a0EF52d753147EAd75;

    address public constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    address public UNIVERSAL_ROUTER = vm.envAddress("UNIVERSAL_ROUTER");

    address public constant ISSUE_LOYALTY_TOKEN_HANDLER = 0xCC020D1C7631f738103Aff1FE152FC1c2238c1a9;

    address public constant ISSUE_CREATOR_TOKEN_HANDLER = 0xDDBF89d6B60b28b2236b51787853eb2644140278;

    function run() public {
        vm.startBroadcast();

        SwapHandler swapHandler = new SwapHandler{salt: keccak256("SwapHandler")}(
            UNIVERSAL_ROUTER, ISSUE_LOYALTY_TOKEN_HANDLER, ISSUE_CREATOR_TOKEN_HANDLER, PERMIT2_ADDRESS, OWNER_ADDRESS
        );

        console.log("SwapHandler deployed at", address(swapHandler));

        vm.stopBroadcast();
    }
}
