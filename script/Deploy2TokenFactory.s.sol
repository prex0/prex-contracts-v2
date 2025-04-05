// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PrexTokenFactory} from "../src/token-factory/PrexTokenFactory.sol";
import {CreatorTokenFactory} from "../src/token-factory/CreatorTokenFactory.sol";
import {LoyaltyTokenFactory} from "../src/token-factory/LoyaltyTokenFactory.sol";

contract DeployTokenFactoryScript is Script {
    function run() public {
        vm.startBroadcast();

        CreatorTokenFactory creatorTokenFactory = new CreatorTokenFactory{salt: keccak256("CreatorTokenFactory")}();
        LoyaltyTokenFactory loyaltyTokenFactory = new LoyaltyTokenFactory{salt: keccak256("LoyaltyTokenFactory")}();

        console.log("CreatorTokenFactory deployed at", address(creatorTokenFactory));
        console.log("LoyaltyTokenFactory deployed at", address(loyaltyTokenFactory));

        vm.stopBroadcast();
    }
}
