// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

struct DrawLotteryOrder {
    address dispatcher;
    address sender;
    uint256 deadline;
    uint256 nonce;
    uint256 lotteryId;
    uint256 amount;
}

/// @notice helpers for handling DrawLotteryOrder
library DrawLotteryOrderLib {
    bytes internal constant DRAW_LOTTERY_ORDER_TYPE_S = abi.encodePacked(
        "DrawLotteryOrder(",
        "address dispatcher,",
        "address sender,",
        "uint256 deadline,",
        "uint256 nonce,",
        "uint256 lotteryId)"
    );

    /// @dev Note that sub-structs have to be defined in alphabetical order in the EIP-712 spec

    bytes internal constant DRAW_LOTTERY_ORDER_TYPE = abi.encodePacked(DRAW_LOTTERY_ORDER_TYPE_S);
    bytes32 internal constant DRAW_LOTTERY_ORDER_TYPE_HASH = keccak256(DRAW_LOTTERY_ORDER_TYPE);

    string internal constant TOKEN_PERMISSIONS_TYPE = "TokenPermissions(address token,uint256 amount)";
    string internal constant PERMIT2_ORDER_TYPE =
        string(abi.encodePacked("DrawLotteryOrder witness)", DRAW_LOTTERY_ORDER_TYPE_S, TOKEN_PERMISSIONS_TYPE));

    /// @notice hash the given order
    /// @param order the order to hash
    /// @return the eip-712 order hash
    function hash(DrawLotteryOrder memory order) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                DRAW_LOTTERY_ORDER_TYPE_HASH,
                order.dispatcher,
                order.sender,
                order.deadline,
                order.nonce,
                order.lotteryId
            )
        );
    }
}
