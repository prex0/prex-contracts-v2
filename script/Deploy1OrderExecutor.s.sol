// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Importing necessary libraries and contracts
import {Script, console} from "forge-std/Script.sol";
import {OrderExecutor} from "../src/OrderExecutor.sol";
import {BuyPrexPointHandler} from "../src/handlers/point/BuyPrexPointHandler.sol";

// This script is designed to deploy the OrderExecutor and BuyPrexPointHandler contracts to ensure they are set up correctly and can interact as intended.
contract OrderExecutorScript is Script {
    // Instance of the OrderExecutor contract to manage order execution logic
    OrderExecutor public orderExecutor;

    // Constant address for the owner of the deployed contracts, ensuring control and management by a specific entity
    address public constant OWNER_ADDRESS =
        0x51B89C499F3038756Eff64a0EF52d753147EAd75;

    // Constant address for the Permit2 contract, which is required for handling permissions within the system
    address public constant PERMIT2_ADDRESS =
        0x000000000022D473030F116dDEE9F6B43aC78BA3;

    address public constant POINT_MINTER =
        0xAd77509161a564cF02790E12d56928940a556cbB;

    // Main function to deploy the contracts, ensuring they are initialized and linked properly
    function run() public {
        vm.startBroadcast();

        // Deploy the BuyPrexPointHandler contract with a specific salt to ensure a predictable and deterministic address, which is crucial for contract interactions
        BuyPrexPointHandler pointHandler = new BuyPrexPointHandler{
            salt: keccak256("Ver3")
        }(msg.sender, PERMIT2_ADDRESS, OWNER_ADDRESS);

        pointHandler.addMinter(POINT_MINTER);

        // Deploy the OrderExecutor contract with a specific salt and link it to the point handler to ensure it can manage point-related operations
        orderExecutor = new OrderExecutor{salt: keccak256("Ver3")}(
            address(pointHandler.point()),
            msg.sender
        );

        pointHandler.setConsumer(address(orderExecutor));

        pointHandler.transferOwnership(OWNER_ADDRESS);

        // Add the point handler to the order executor to enable it to handle point transactions
        orderExecutor.addHandler(address(pointHandler));

        // Transfer ownership of the order executor to the specified owner address to ensure proper governance and control
        orderExecutor.transferOwnership(OWNER_ADDRESS);

        // Log the addresses of the deployed contracts for verification and record-keeping purposes
        console.log("OrderExecutor deployed at", address(orderExecutor));
        console.log("BuyPrexPointHandler deployed at", address(pointHandler));
        console.log("PrexPoint deployed at", address(pointHandler.point()));

        vm.stopBroadcast();
    }
}
