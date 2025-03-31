// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../../interfaces/IOrderHandler.sol";

struct SwapRequest {
    address dispatcher;
    uint256 policyId;
    address swapper;
    address recipient;
    uint256 deadline;
    uint256 nonce;
    bool exactIn;
    address tokenIn;
    address tokenOut;
    uint256 amountIn;
    uint256 amountOut;
}

/// @notice helpers for handling TransferRequest
library SwapRequestLib {
    bytes internal constant SWAP_REQUEST_TYPE_S = abi.encodePacked(
        "SwapRequest(",
        "address dispatcher,",
        "uint256 policyId,",
        "address swapper,",
        "address recipient,",
        "uint256 deadline,",
        "uint256 nonce,",
        "bool exactIn,",
        "address tokenIn,",
        "address tokenOut,",
        "uint256 amountIn,",
        "uint256 amountOut)"
    );

    /// @dev Note that sub-structs have to be defined in alphabetical order in the EIP-712 spec

    bytes internal constant SWAP_REQUEST_TYPE = abi.encodePacked(SWAP_REQUEST_TYPE_S);
    bytes32 internal constant SWAP_REQUEST_TYPE_HASH = keccak256(SWAP_REQUEST_TYPE);

    string internal constant TOKEN_PERMISSIONS_TYPE = "TokenPermissions(address token,uint256 amount)";
    string internal constant PERMIT2_ORDER_TYPE =
        string(abi.encodePacked("SwapRequest witness)", SWAP_REQUEST_TYPE_S, TOKEN_PERMISSIONS_TYPE));

    /// @notice hash the given request
    /// @param request the request to hash
    /// @return the eip-712 request hash
    function hash(SwapRequest memory request) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                SWAP_REQUEST_TYPE_HASH,
                request.dispatcher,
                request.policyId,
                request.swapper,
                request.recipient,
                request.deadline,
                request.nonce,
                request.exactIn,
                request.tokenIn,
                request.tokenOut,
                request.amountIn,
                request.amountOut
            )
        );
    }

    function getOrderReceipt(SwapRequest memory request) internal pure returns (OrderReceipt memory) {
        address[] memory tokens = new address[](1);

        tokens[0] = request.tokenIn;
        tokens[1] = request.tokenOut;

        return OrderReceipt({tokens: tokens, user: request.swapper, policyId: request.policyId, points: 0});
    }
}
