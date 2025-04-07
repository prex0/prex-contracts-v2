// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ProfileRegistryV2} from "../src/data/ProfileRegistryV2.sol";
import {TokenRegistry} from "../src/data/TokenRegistry.sol";
import {BuyLoyaltyPointHandler} from "../src/handlers/point/BuyLoyaltyPointHandler.sol";
import {IssueCreatorTokenHandler} from "../src/handlers/token/IssueCreatorTokenHandler.sol";
import {IssueTokenHandler} from "../src/handlers/token/IssueTokenHandler.sol";
import {IssueLoyaltyTokenHandler} from "../src/handlers/token/IssueLoyaltyTokenHandler.sol";

contract DeployTokenHandlerScript is Script {
    address public constant OWNER_ADDRESS = 0x51B89C499F3038756Eff64a0EF52d753147EAd75;

    address public constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    address public constant TOKEN_REGISTRY = 0x57F3891da461C783231A79328aa11AE6C724E9B2;

    address public constant ORDER_EXECUTOR = 0x1e2F0cF2f6E51103075fA6beB605bA5C898c5e2B;

    function run() public {
        vm.startBroadcast();

        // Deploy Token Issue Handler
        IssueTokenHandler issueTokenHandler =
            new IssueTokenHandler{salt: keccak256("Ver2")}(PERMIT2_ADDRESS, TOKEN_REGISTRY, msg.sender);

        issueTokenHandler.setOrderExecutor(ORDER_EXECUTOR);

        issueTokenHandler.transferOwnership(OWNER_ADDRESS);

        console.log("IssueTokenHandler deployed at", address(issueTokenHandler));

        vm.stopBroadcast();
    }
}
