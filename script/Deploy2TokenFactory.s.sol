// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PrexTokenFactory} from "../src/token-factory/PrexTokenFactory.sol";
import {CreatorTokenFactory} from "../src/token-factory/CreatorTokenFactory.sol";

contract DeployTokenFactoryScript is Script {
    function run() public {
        vm.startBroadcast();

        PrexTokenFactory prexTokenFactory = new PrexTokenFactory{salt: keccak256("PrexTokenFactory")}();
        CreatorTokenFactory creatorTokenFactory = new CreatorTokenFactory{salt: keccak256("CreatorTokenFactory")}();

        console.log("PrexTokenFactory deployed at", address(prexTokenFactory));
        console.log("CreatorTokenFactory deployed at", address(creatorTokenFactory));

        vm.stopBroadcast();
    }
}
