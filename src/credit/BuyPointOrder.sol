// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {OrderReceipt} from "../interfaces/IOrderHandler.sol";

struct BuyPointOrder {
    address dispatcher;
    uint256 policyId;
    address buyer;
    uint256 deadline;
    uint256 nonce;
    uint256 amount;
}

/// @notice helpers for handling BuyPointOrder
library BuyPointOrderLib {
    bytes internal constant BUY_POINT_ORDER_TYPE_S = abi.encodePacked(
        "BuyPointOrder(",
        "address dispatcher,",
        "uint256 policyId,",
        "address buyer,",
        "uint256 deadline,",
        "uint256 nonce,",
        "uint256 amount)"
    );

    /// @dev Note that sub-structs have to be defined in alphabetical order in the EIP-712 spec

    bytes internal constant BUY_POINT_ORDER_TYPE = abi.encodePacked(BUY_POINT_ORDER_TYPE_S);
    bytes32 internal constant BUY_POINT_ORDER_TYPE_HASH = keccak256(BUY_POINT_ORDER_TYPE);

    string internal constant TOKEN_PERMISSIONS_TYPE = "TokenPermissions(address token,uint256 amount)";
    string internal constant PERMIT2_ORDER_TYPE =
        string(abi.encodePacked("BuyPointOrder witness)", BUY_POINT_ORDER_TYPE_S, TOKEN_PERMISSIONS_TYPE));

    /// @notice hash the given order
    /// @param order the order to hash
    /// @return the eip-712 order hash
    function hash(BuyPointOrder memory order) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                BUY_POINT_ORDER_TYPE_HASH,
                order.dispatcher,
                order.policyId,
                order.buyer,
                order.deadline,
                order.nonce,
                order.amount
            )
        );
    }

    function getOrderReceipt(BuyPointOrder memory order) internal pure returns (OrderReceipt memory) {
        address[] memory tokens = new address[](0);
        return OrderReceipt({user: order.buyer, policyId: order.policyId, points: 0, tokens: tokens, result: ""});
    }
}
