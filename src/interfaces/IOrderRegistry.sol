// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IOrderHandler {
    function validateUserOrder(address user, bytes calldata callData, bytes calldata signature, bytes calldata appSig)
        external
        view
        returns (bool);

    function execute(address user, bytes calldata callData) external;
}
