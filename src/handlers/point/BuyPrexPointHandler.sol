// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../interfaces/IOrderHandler.sol";
import "../../credit/PrexPointMarket.sol";

/**
 * @title BuyPrexPointHandler
 * @notice Pointを買うためのハンドラー
 */
contract BuyPrexPointHandler is IOrderHandler, PrexPointMarket {
    using BuyPointOrderLib for BuyPointOrder;

    constructor(address _owner, address _permit2, address _feeRecipient)
        PrexPointMarket("PrexPoint", "PREXPOINT", _owner, _permit2, _feeRecipient)
    {}

    function execute(address, SignedOrder calldata order, bytes calldata) external returns (OrderReceipt memory) {
        BuyPointOrder memory request = abi.decode(order.order, (BuyPointOrder));

        buy(request, order.signature);

        return request.getOrderReceipt();
    }
}
