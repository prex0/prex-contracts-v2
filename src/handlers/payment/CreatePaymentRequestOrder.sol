// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../../src/interfaces/IOrderHandler.sol";

struct CreatePaymentRequestOrder {
    address dispatcher;
    uint256 policyId;
    address creator;
    address recipient;
    uint256 deadline;
    uint256 nonce;
    uint256 amount;
    address token;
    string name;
}

/// @notice helpers for handling CreatePaymentRequest
library CreatePaymentRequestOrderLib {
    bytes internal constant CREATE_PAYMENT_REQUEST_ORDER_TYPE_S = abi.encodePacked(
        "CreatePaymentRequestOrder(",
        "address dispatcher,",
        "uint256 policyId,",
        "address creator,",
        "address recipient,",
        "uint256 deadline,",
        "uint256 nonce,",
        "uint256 amount,",
        "address token,",
        "string name)"
    );

    /// @dev Note that sub-structs have to be defined in alphabetical order in the EIP-712 spec

    bytes internal constant CREATE_PAYMENT_REQUEST_ORDER_TYPE = abi.encodePacked(CREATE_PAYMENT_REQUEST_ORDER_TYPE_S);
    bytes32 internal constant CREATE_PAYMENT_REQUEST_ORDER_TYPE_HASH = keccak256(CREATE_PAYMENT_REQUEST_ORDER_TYPE);

    string internal constant TOKEN_PERMISSIONS_TYPE = "TokenPermissions(address token,uint256 amount)";
    string internal constant PERMIT2_ORDER_TYPE = string(
        abi.encodePacked(
            "CreatePaymentRequestOrder witness)", CREATE_PAYMENT_REQUEST_ORDER_TYPE_S, TOKEN_PERMISSIONS_TYPE
        )
    );

    /// @notice hash the given request
    /// @param request the request to hash
    /// @return the eip-712 request hash
    function hash(CreatePaymentRequestOrder memory request) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                CREATE_PAYMENT_REQUEST_ORDER_TYPE_HASH,
                request.dispatcher,
                request.policyId,
                request.creator,
                request.recipient,
                request.deadline,
                request.nonce,
                request.amount,
                request.token,
                request.name
            )
        );
    }

    function getOrderReceipt(CreatePaymentRequestOrder memory request, uint256 points)
        internal
        pure
        returns (OrderReceipt memory)
    {
        address[] memory tokens = new address[](1);

        tokens[0] = request.token;

        return OrderReceipt({tokens: tokens, user: request.creator, policyId: request.policyId, points: points});
    }
}
