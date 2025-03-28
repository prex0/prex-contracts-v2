// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {SignedOrder, OrderReceipt} from "./IOrderHandler.sol";

struct OrderHeader {
    address dispatcher;
    uint256 methodId;
    bytes32 orderHash;
    bytes32 identifier;
}

interface IOrderExecutor {
    function execute(SignedOrder calldata order, bytes calldata facilitatorData)
        external
        returns (OrderReceipt memory);
}
