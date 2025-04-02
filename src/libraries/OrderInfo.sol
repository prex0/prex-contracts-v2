// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

struct OrderInfo {
    address dispatcher;
    uint256 policyId;
    address sender;
    uint256 deadline;
    uint256 nonce;
}

library OrderInfoLib {
    bytes internal constant ORDER_INFO_TYPE_S = abi.encodePacked(
        "OrderInfo(",
        "address dispatcher,",
        "uint256 policyId,",
        "address sender,",
        "uint256 deadline,",
        "uint256 nonce)"
    );

    bytes32 internal constant ORDER_INFO_TYPE_HASH = keccak256(ORDER_INFO_TYPE_S);

    /// @notice hash the given order info
    /// @param orderInfo the order info to hash
    /// @return the eip-712 order info hash
    function hash(OrderInfo memory orderInfo) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                ORDER_INFO_TYPE_HASH,
                orderInfo.dispatcher,
                orderInfo.policyId,
                orderInfo.sender,
                orderInfo.deadline,
                orderInfo.nonce
            )
        );
    }
}
