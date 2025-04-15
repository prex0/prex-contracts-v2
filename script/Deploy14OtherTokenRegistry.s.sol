// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {OtherTokenRegistry} from "../src/data/OtherTokenRegistry.sol";

contract DeployOtherTokenRegistryScript is Script {
    OtherTokenRegistry public otherTokenRegistry;

    address public constant OWNER_ADDRESS = 0x51B89C499F3038756Eff64a0EF52d753147EAd75;

    function run() public {
        vm.startBroadcast();

        otherTokenRegistry = new OtherTokenRegistry{salt: keccak256("OtherTokenRegistry")}(
            OWNER_ADDRESS
        );

        console.log("OtherTokenRegistry deployed at", address(otherTokenRegistry));

        vm.stopBroadcast();
    }
}
