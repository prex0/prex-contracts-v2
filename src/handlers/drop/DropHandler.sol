// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../interfaces/IOrderHandler.sol";
import "./DropRequestDispatcher.sol";
import {Owned} from "../../../lib/solmate/src/auth/Owned.sol";

contract DropHandler is IOrderHandler, DropRequestDispatcher {
    error InvalidMethodId();

    constructor(address _permit2, address _owner) DropRequestDispatcher(_permit2, _owner) {}

    /**
     * @notice ドロップの実行
     * @param order オーダー
     * @return オーダーの結果
     */
    function execute(address, SignedOrder calldata order, bytes calldata)
        external
        onlyOrderExecutor
        returns (OrderReceipt memory)
    {
        if (order.methodId == 1) {
            CreateDropRequest memory request = abi.decode(order.order, (CreateDropRequest));

            return submitRequest(request, order.signature, keccak256(order.order));
        } else if (order.methodId == 2) {
            ClaimDropRequest memory recipientData = abi.decode(order.order, (ClaimDropRequest));

            return distribute(recipientData, keccak256(order.order));
        } else {
            revert InvalidMethodId();
        }
    }
}
