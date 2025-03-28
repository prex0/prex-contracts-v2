// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../../src/interfaces/IOrderHandler.sol";

struct LinkTransferRequest {
    address dispatcher;
    uint256 policyId;
    address sender;
    uint256 deadline;
    uint256 nonce;
    uint256 amount;
    address token;
    address publicKey;
    bytes metadata;
}

/// @notice helpers for handling TransferRequest
library LinkTransferRequestLib {
    bytes internal constant LINK_TRANSFER_REQUEST_TYPE_S = abi.encodePacked(
        "LinkTransferRequest(",
        "address dispatcher,",
        "uint256 policyId,",
        "address sender,",
        "uint256 deadline,",
        "uint256 nonce,",
        "uint256 amount,",
        "address token,",
        "address publicKey,",
        "bytes metadata)"
    );

    /// @dev Note that sub-structs have to be defined in alphabetical order in the EIP-712 spec

    bytes internal constant LINK_TRANSFER_REQUEST_TYPE = abi.encodePacked(LINK_TRANSFER_REQUEST_TYPE_S);
    bytes32 internal constant LINK_TRANSFER_REQUEST_TYPE_HASH = keccak256(LINK_TRANSFER_REQUEST_TYPE);

    string internal constant TOKEN_PERMISSIONS_TYPE = "TokenPermissions(address token,uint256 amount)";
    string internal constant PERMIT2_ORDER_TYPE =
        string(abi.encodePacked("LinkTransferRequest witness)", LINK_TRANSFER_REQUEST_TYPE_S, TOKEN_PERMISSIONS_TYPE));

    /// @notice hash the given request
    /// @param request the request to hash
    /// @return the eip-712 request hash
    function hash(LinkTransferRequest memory request) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                LINK_TRANSFER_REQUEST_TYPE_HASH,
                request.dispatcher,
                request.policyId,
                request.sender,
                request.deadline,
                request.nonce,
                request.amount,
                request.token,
                request.publicKey,
                keccak256(request.metadata)
            )
        );
    }

    function getOrderReceipt(LinkTransferRequest memory request, uint256 points)
        internal
        pure
        returns (OrderReceipt memory)
    {
        address[] memory tokens = new address[](1);

        tokens[0] = request.token;

        return OrderReceipt({tokens: tokens, user: request.sender, policyId: request.policyId, points: points, result: ""});
    }
}
