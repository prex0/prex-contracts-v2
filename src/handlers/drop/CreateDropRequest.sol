// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../../src/interfaces/IOrderHandler.sol";

struct OrderInfo {
    address dispatcher;
    uint256 policyId;
    bool isPrepaid;
    address sender;
    uint256 deadline;
    uint256 nonce;
    address token;
}

struct CreateDropRequest {
    OrderInfo orderInfo;
    uint256 dropPolicyId;
    address publicKey;
    uint256 amount;
    uint256 amountPerWithdrawal;
    uint256 expiry;
    string name;
}

library OrderInfoLib {
    bytes internal constant ORDER_INFO_TYPE_S = abi.encodePacked(
        "OrderInfo(",
        "address dispatcher,",
        "uint256 policyId,",
        "bool isPrepaid,",
        "address sender,",
        "uint256 deadline,",
        "uint256 nonce,",
        "address token)"
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
                orderInfo.isPrepaid,
                orderInfo.sender,
                orderInfo.deadline,
                orderInfo.nonce,
                orderInfo.token
            )
        );
    }
}

library CreateDropRequestLib {
    bytes internal constant CREATE_DROP_REQUEST_TYPE_S = abi.encodePacked(
        "CreateDropRequest(",
        "OrderInfo orderInfo,",
        "uint256 dropPolicyId,",
        "address publicKey,",
        "uint256 amount,",
        "uint256 amountPerWithdrawal,",
        "uint256 expiry,",
        "string name)"
    );

    /// @dev Note that sub-structs have to be defined in alphabetical order in the EIP-712 spec

    bytes internal constant CREATE_DROP_REQUEST_TYPE = abi.encodePacked(CREATE_DROP_REQUEST_TYPE_S);
    bytes32 internal constant CREATE_DROP_REQUEST_TYPE_HASH = keccak256(CREATE_DROP_REQUEST_TYPE);

    string internal constant TOKEN_PERMISSIONS_TYPE = "TokenPermissions(address token,uint256 amount)";

    string internal constant PERMIT2_ORDER_TYPE = string(
        abi.encodePacked(
            "CreateDropRequest witness)",
            CREATE_DROP_REQUEST_TYPE_S,
            OrderInfoLib.ORDER_INFO_TYPE_S,
            TOKEN_PERMISSIONS_TYPE
        )
    );

    uint256 private constant MAX_EXPIRY = 360 days;

    /// @notice hash the given request
    /// @param request the request to hash
    /// @return the eip-712 request hash
    function hash(CreateDropRequest memory request) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                CREATE_DROP_REQUEST_TYPE_HASH,
                OrderInfoLib.hash(request.orderInfo),
                request.dropPolicyId,
                request.publicKey,
                request.amount,
                request.amountPerWithdrawal,
                request.expiry,
                keccak256(bytes(request.name))
            )
        );
    }

    function verify(CreateDropRequest memory request) internal view returns (bool) {
        if (request.expiry <= block.timestamp) {
            return false;
        }

        if (request.expiry > block.timestamp + MAX_EXPIRY) {
            return false;
        }

        if (request.amount <= 0) {
            return false;
        }

        if (request.amountPerWithdrawal <= 0) {
            return false;
        }

        return true;
    }

    function getOrderReceipt(CreateDropRequest memory request, uint256 points)
        internal
        pure
        returns (OrderReceipt memory)
    {
        address[] memory tokens = new address[](1);

        tokens[0] = request.orderInfo.token;

        uint256 numberOfWithdrawals = getNumberOfWithdrawals(request);

        return OrderReceipt({
            tokens: tokens,
            user: request.orderInfo.sender,
            policyId: request.dropPolicyId,
            points: request.orderInfo.isPrepaid ? points * numberOfWithdrawals : points
        });
    }

    function getNumberOfWithdrawals(CreateDropRequest memory request) internal pure returns (uint256) {
        return request.amount / request.amountPerWithdrawal;
    }
}
