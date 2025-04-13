// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Importing necessary libraries and contracts
import {Script, console} from "forge-std/Script.sol";
import {OrderExecutor} from "../src/OrderExecutor.sol";
import {BuyPrexPointHandler} from "../src/handlers/point/BuyPrexPointHandler.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

// This script is designed to deploy the OrderExecutor and BuyPrexPointHandler contracts to ensure they are set up correctly and can interact as intended.
contract OrderExecutorV2Script is Script {
    // Instance of the OrderExecutor contract to manage order execution logic
    OrderExecutor public orderExecutor;

    // Constant address for the owner of the deployed contracts, ensuring control and management by a specific entity
    address public constant OWNER_ADDRESS = 0x51B89C499F3038756Eff64a0EF52d753147EAd75;
    
    address public constant PREX_POINT = 0xC2835f0fC2f63AB2057F6e74fA213B6a0cE04C4A;

    // Main function to deploy the contracts, ensuring they are initialized and linked properly
    function run() public {
        vm.startBroadcast();

        // Deploy the OrderExecutor contract with a specific salt and link it to the point handler to ensure it can manage point-related operations
        orderExecutor = new OrderExecutor{salt: keccak256("Ver2")}();

        bytes memory initData = abi.encodeWithSelector(
            OrderExecutor.initialize.selector,
            PREX_POINT,
            OWNER_ADDRESS
        );

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(orderExecutor),
            OWNER_ADDRESS,
            initData
        );

        // Log the addresses of the deployed contracts for verification and record-keeping purposes
        console.log("OrderExecutor deployed at", address(proxy));

        vm.stopBroadcast();
    }
}
