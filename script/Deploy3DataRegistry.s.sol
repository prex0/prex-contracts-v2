// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ProfileRegistryV2} from "../src/data/ProfileRegistryV2.sol";
import {TokenRegistry} from "../src/data/TokenRegistry.sol";

contract DeployDataRegistryScript is Script {
    ProfileRegistryV2 public profileRegistryV2;
    TokenRegistry public tokenRegistry;

    function run() public {
        vm.startBroadcast();

        profileRegistryV2 = new ProfileRegistryV2{salt: keccak256("ProfileRegistryV2")}();
        tokenRegistry = new TokenRegistry{salt: keccak256("TokenRegistry")}();

        console.log("ProfileRegistryV2 deployed at", address(profileRegistryV2));
        console.log("TokenRegistry deployed at", address(tokenRegistry));

        vm.stopBroadcast();
    }
}
