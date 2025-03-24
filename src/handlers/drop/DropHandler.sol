// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../interfaces/IOrderHandler.sol";
import "./DropRequestDispatcher.sol";

contract DropHandler is IOrderHandler {
    using DropRequestLib for DropRequest;

    DropRequestDispatcher public dropRequestDispatcher;

    constructor(address _dropRequestDispatcher) {
        dropRequestDispatcher = DropRequestDispatcher(_dropRequestDispatcher);
    }

    function execute(
        address _facilitator,
        bytes calldata order,
        bytes calldata signature
    ) external returns (OrderHeader memory, OrderReceipt memory) {
        RecipientData memory recipientData = abi.decode(order, (RecipientData));

        return dropRequestDispatcher.distribute(recipientData);
    }
}
