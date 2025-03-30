// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../../../interfaces/IOrderHandler.sol";

struct IssueMintableTokenRequest {
    address dispatcher;
    uint256 policyId;
    address issuer;
    address recipient;
    uint256 deadline;
    uint256 nonce;
    uint256 initialSupply;
    string name;
    string symbol;
    bytes32 pictureHash;
    string metadata;
}

/// @notice helpers for handling TransferRequest
library IssueMintableTokenRequestLib {
    bytes internal constant ISSUE_MINTABLE_TOKEN_REQUEST_TYPE_S = abi.encodePacked(
        "IssueMintableTokenRequest(",
        "address dispatcher,",
        "uint256 policyId,",
        "address issuer,",
        "address recipient,",
        "uint256 deadline,",
        "uint256 nonce,",
        "uint256 initialSupply,",
        "string name,",
        "string symbol,",
        "bytes32 pictureHash,",
        "string metadata)"
    );

    /// @dev Note that sub-structs have to be defined in alphabetical order in the EIP-712 spec

    bytes internal constant ISSUE_MINTABLE_TOKEN_REQUEST_TYPE = abi.encodePacked(ISSUE_MINTABLE_TOKEN_REQUEST_TYPE_S);
    bytes32 internal constant ISSUE_MINTABLE_TOKEN_REQUEST_TYPE_HASH = keccak256(ISSUE_MINTABLE_TOKEN_REQUEST_TYPE);

    string internal constant TOKEN_PERMISSIONS_TYPE = "TokenPermissions(address token,uint256 amount)";
    string internal constant PERMIT2_ORDER_TYPE = string(
        abi.encodePacked(
            "IssueMintableTokenRequest witness)", ISSUE_MINTABLE_TOKEN_REQUEST_TYPE_S, TOKEN_PERMISSIONS_TYPE
        )
    );

    /// @notice hash the given request
    /// @param request the request to hash
    /// @return the eip-712 request hash
    function hash(IssueMintableTokenRequest memory request) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                ISSUE_MINTABLE_TOKEN_REQUEST_TYPE_HASH,
                request.dispatcher,
                request.policyId,
                request.issuer,
                request.recipient,
                request.deadline,
                request.nonce,
                request.initialSupply,
                keccak256(bytes(request.name)),
                keccak256(bytes(request.symbol)),
                request.pictureHash,
                keccak256(bytes(request.metadata))
            )
        );
    }

    function getOrderReceipt(IssueMintableTokenRequest memory request, uint256 points)
        internal
        pure
        returns (OrderReceipt memory)
    {
        address[] memory tokens = new address[](0);

        return OrderReceipt({tokens: tokens, user: request.issuer, policyId: request.policyId, points: points});
    }
}
