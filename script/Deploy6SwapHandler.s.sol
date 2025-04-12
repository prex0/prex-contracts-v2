// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SwapHandler} from "../src/handlers/swap/SwapHandler.sol";

contract Deploy6SwapHandlerScript is Script {
    address public constant OWNER_ADDRESS = 0x51B89C499F3038756Eff64a0EF52d753147EAd75;

    address public constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    address public constant UNIVERSAL_ROUTER = 0x851116D9223fabED8E56C0E6b8Ad0c31d98B3507;

    address public constant ISSUE_LOYALTY_TOKEN_HANDLER = 0xa140d4D065f9518dC20ECa9467DCc323Cdb621A9;

    address public constant ISSUE_CREATOR_TOKEN_HANDLER = 0xC7781b2445D9822a35Fe1663ACEDe4CA3771867c;

    function run() public {
        vm.startBroadcast();

        SwapHandler swapHandler = new SwapHandler{salt: keccak256("SwapHandler")}(
            UNIVERSAL_ROUTER, ISSUE_LOYALTY_TOKEN_HANDLER, ISSUE_CREATOR_TOKEN_HANDLER, PERMIT2_ADDRESS, OWNER_ADDRESS
        );

        console.log("SwapHandler deployed at", address(swapHandler));

        vm.stopBroadcast();
    }
}
