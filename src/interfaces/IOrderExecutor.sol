// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IOrderExecutor {
    function execute(
        address orderHandler,
        bytes calldata order,
        bytes calldata signature,
        bytes calldata appSig
    ) external;
}
