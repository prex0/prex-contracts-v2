// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {SignedOrder} from "./IOrderHandler.sol";

interface IOrderExecutor {
    function execute(SignedOrder calldata order, bytes calldata facilitatorData) external;
}
