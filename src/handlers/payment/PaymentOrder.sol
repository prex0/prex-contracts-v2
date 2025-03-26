// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../../src/interfaces/IOrderHandler.sol";

struct PaymentOrder {
    address dispatcher;
    address sender;
    uint256 deadline;
    uint256 nonce;
    bytes32 requestId;
    bytes metadata;
}

/// @notice helpers for handling TransferRequest
library PaymentOrderLib {
    bytes internal constant PAYMENT_ORDER_TYPE_S = abi.encodePacked(
        "PaymentOrder(",
        "address dispatcher,",
        "address sender,",
        "uint256 deadline,",
        "uint256 nonce,",
        "bytes32 requestId,",
        "bytes metadata)"
    );

    /// @dev Note that sub-structs have to be defined in alphabetical order in the EIP-712 spec

    bytes internal constant PAYMENT_ORDER_TYPE = abi.encodePacked(PAYMENT_ORDER_TYPE_S);
    bytes32 internal constant PAYMENT_ORDER_TYPE_HASH = keccak256(PAYMENT_ORDER_TYPE);

    string internal constant TOKEN_PERMISSIONS_TYPE = "TokenPermissions(address token,uint256 amount)";
    string internal constant PERMIT2_ORDER_TYPE =
        string(abi.encodePacked("PaymentOrder witness)", PAYMENT_ORDER_TYPE_S, TOKEN_PERMISSIONS_TYPE));

    /// @notice hash the given request
    /// @param request the request to hash
    /// @return the eip-712 request hash
    function hash(PaymentOrder memory request) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                PAYMENT_ORDER_TYPE_HASH,
                request.dispatcher,
                request.sender,
                request.deadline,
                request.nonce,
                request.requestId,
                keccak256(request.metadata)
            )
        );
    }
}
