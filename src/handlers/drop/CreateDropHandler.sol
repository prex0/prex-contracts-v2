// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../interfaces/IOrderHandler.sol";
import "./DropRequest.sol";
import "./DropRequestDispatcher.sol";

contract CreateDropHandler is IOrderHandler {
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
        DropRequest memory request = abi.decode(order, (DropRequest));

        return dropRequestDispatcher.submitRequest(request, signature);
    }
}
