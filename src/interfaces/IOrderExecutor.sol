// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {SignedOrder} from "./IOrderHandler.sol";

struct OrderHeader {
    address dispatcher;
    uint256 methodId;
    bytes32 orderHash;
}

interface IOrderExecutor {
    function execute(SignedOrder calldata order, bytes calldata facilitatorData) external;
}
