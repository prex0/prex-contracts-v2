// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IOrderHandler, OrderHeader, OrderReceipt} from "./interfaces/IOrderHandler.sol";

contract TransferOrder is IOrderHandler {
    function execute(
        address user,
        bytes calldata order,
        bytes calldata signature
    ) external returns (OrderHeader memory, OrderReceipt memory) {
        return (OrderHeader(
            user,
            0,
            0,
            0
        ), OrderReceipt(0));
    }
}
