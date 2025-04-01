// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../interfaces/IOrderHandler.sol";
import "./DropRequestDispatcher.sol";
import {Owned} from "../../../lib/solmate/src/auth/Owned.sol";

contract DropHandler is IOrderHandler, DropRequestDispatcher, Owned {
    error InvalidMethodId();

    address public orderExecutor;

    error CallerMustBeOrderExecutor();

    modifier onlyOrderExecutor() {
        if (msg.sender != orderExecutor) {
            revert CallerMustBeOrderExecutor();
        }
        _;
    }

    constructor(address _permit2, address _owner) DropRequestDispatcher(_permit2) Owned(_owner) {}

    function setOrderExecutor(address _orderExecutor) external onlyOwner {
        orderExecutor = _orderExecutor;
    }

    function execute(address, SignedOrder calldata order, bytes calldata)
        external
        onlyOrderExecutor
        returns (OrderReceipt memory)
    {
        if (order.methodId == 1) {
            CreateDropRequest memory request = abi.decode(order.order, (CreateDropRequest));

            return submitRequest(request, order.signature);
        } else if (order.methodId == 2) {
            ClaimDropRequest memory recipientData = abi.decode(order.order, (ClaimDropRequest));

            return distribute(recipientData);
        } else {
            revert InvalidMethodId();
        }
    }
}
