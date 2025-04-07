// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../interfaces/IOrderHandler.sol";
import "./MultiPrizeLottery.sol";
import "./orders/CreateLotteryOrder.sol";
import "./orders/DrawLotteryOrder.sol";

contract LotteryHandler is IOrderHandler, MultiPrizeLottery {
    error InvalidMethodId();

    constructor(address _permit2, address _owner) MultiPrizeLottery(_permit2, _owner) {}

    function execute(address, SignedOrder calldata order, bytes calldata)
        external
        onlyOrderExecutor
        returns (OrderReceipt memory)
    {
        if (order.methodId == 1) {
            CreateLotteryOrder memory request = abi.decode(order.order, (CreateLotteryOrder));

            return createLottery(request, order.signature, keccak256(order.order));
        } else if (order.methodId == 2) {
            DrawLotteryOrder memory request = abi.decode(order.order, (DrawLotteryOrder));

            return drawLottery(request, order.signature, keccak256(order.order));
        } else {
            revert InvalidMethodId();
        }
    }
}
