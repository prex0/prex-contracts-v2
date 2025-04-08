// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ProfileRegistryV2} from "../src/data/ProfileRegistryV2.sol";
import {TokenRegistry} from "../src/data/TokenRegistry.sol";
import {BuyLoyaltyPointHandler} from "../src/handlers/point/BuyLoyaltyPointHandler.sol";
import {IssueCreatorTokenHandler} from "../src/handlers/token/IssueCreatorTokenHandler.sol";
import {IssueTokenHandler} from "../src/handlers/token/IssueTokenHandler.sol";
import {IssueLoyaltyTokenHandler} from "../src/handlers/token/IssueLoyaltyTokenHandler.sol";
import {PumHook} from "../src/swap/hooks/PumHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";

contract DeployLoyaltyHandlerScript is Script {
    address public constant OWNER_ADDRESS = 0x51B89C499F3038756Eff64a0EF52d753147EAd75;

    address public constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    address public DAI_ADDRESS = vm.envAddress("DAI_ADDRESS");

    address public constant LOYALTY_TOKEN_FACTORY = 0xE74dcAec463c07DBAeCAac55e95d4c9Cd133BED0;

    address public constant TOKEN_REGISTRY = 0x57F3891da461C783231A79328aa11AE6C724E9B2;

    address public constant POINT_MINTER = 0xAd77509161a564cF02790E12d56928940a556cbB;

    function run() public {
        vm.startBroadcast();

        // Deploy Loyalty Point and Market
        BuyLoyaltyPointHandler loyaltyPointHandler =
            new BuyLoyaltyPointHandler{salt: keccak256("Ver3")}(msg.sender, PERMIT2_ADDRESS, OWNER_ADDRESS);

        loyaltyPointHandler.addMinter(POINT_MINTER);

        loyaltyPointHandler.transferOwnership(OWNER_ADDRESS);

        console.log("BuyLoyaltyPointHandler deployed at", address(loyaltyPointHandler));
        console.log("LOYALTY Point deployed at", address(loyaltyPointHandler.point()));

        // Deploy Loyalty Token Issue Handler
        IssueLoyaltyTokenHandler issueLoyaltyTokenHandler = new IssueLoyaltyTokenHandler{salt: keccak256("Ver3")}(
            msg.sender, address(loyaltyPointHandler.point()), TOKEN_REGISTRY, LOYALTY_TOKEN_FACTORY, PERMIT2_ADDRESS
        );

        issueLoyaltyTokenHandler.setDai(DAI_ADDRESS);

        issueLoyaltyTokenHandler.transferOwnership(OWNER_ADDRESS);

        console.log("IssueLoyaltyTokenHandler deployed at", address(issueLoyaltyTokenHandler));

        vm.stopBroadcast();
    }
}
