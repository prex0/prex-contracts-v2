// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {OrderReceipt} from "../../../interfaces/IOrderHandler.sol";

struct CreateLotteryOrder {
    uint256 policyId;
    bool isPrepaid;
    address dispatcher;
    address sender;
    address recipient;
    uint256 deadline;
    uint256 nonce;
    address token;
    string name;
    uint256 entryFee;
    uint256[] prizeCounts;
    string[] prizeNames;
}

/// @notice helpers for handling CreateLotteryOrder
library CreateLotteryOrderLib {
    bytes internal constant CREATE_LOTTERY_ORDER_TYPE_S = abi.encodePacked(
        "CreateLotteryOrder(",
        "uint256 policyId,",
        "bool isPrepaid,",
        "address dispatcher,",
        "address sender,",
        "address recipient,",
        "uint256 deadline,",
        "uint256 nonce,",
        "address token,",
        "string name,",
        "uint256 entryFee,",
        "uint256[] prizeCounts,",
        "string[] prizeNames)"
    );

    /// @dev Note that sub-structs have to be defined in alphabetical order in the EIP-712 spec

    bytes internal constant CREATE_LOTTERY_ORDER_TYPE = abi.encodePacked(CREATE_LOTTERY_ORDER_TYPE_S);
    bytes32 internal constant CREATE_LOTTERY_ORDER_TYPE_HASH = keccak256(CREATE_LOTTERY_ORDER_TYPE);

    string internal constant TOKEN_PERMISSIONS_TYPE = "TokenPermissions(address token,uint256 amount)";
    string internal constant PERMIT2_ORDER_TYPE =
        string(abi.encodePacked("CreateLotteryOrder witness)", CREATE_LOTTERY_ORDER_TYPE_S, TOKEN_PERMISSIONS_TYPE));

    /// @notice hash the given order
    /// @param order the order to hash
    /// @return the eip-712 order hash
    function hash(CreateLotteryOrder memory order) internal pure returns (bytes32) {
        bytes32[] memory prizeNameHashes = new bytes32[](order.prizeNames.length);
        for (uint256 i = 0; i < order.prizeNames.length; i++) {
            prizeNameHashes[i] = keccak256(bytes(order.prizeNames[i]));
        }
        bytes32 prizeNamesHash = keccak256(abi.encodePacked(prizeNameHashes));

        return keccak256(
            abi.encode(
                CREATE_LOTTERY_ORDER_TYPE_HASH,
                order.policyId,
                order.isPrepaid,
                order.dispatcher,
                order.sender,
                order.recipient,
                order.deadline,
                order.nonce,
                order.token,
                keccak256(bytes(order.name)),
                order.entryFee,
                keccak256(abi.encodePacked(order.prizeCounts)),
                prizeNamesHash
            )
        );
    }

    function getOrderReceipt(CreateLotteryOrder memory order, uint256 points)
        internal
        pure
        returns (OrderReceipt memory)
    {
        address[] memory tokens = new address[](1);

        tokens[0] = order.token;

        return OrderReceipt({policyId: order.policyId, user: order.sender, tokens: tokens, points: points});
    }
}
