// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IOrderExecutor} from "./interfaces/IOrderExecutor.sol";
import {IOrderHandler, OrderHeader, OrderReceipt} from "./interfaces/IOrderHandler.sol";
import {IPolicyValidator} from "./interfaces/IPolicyValidator.sol";
import {IUserPoints} from "./interfaces/IUserPoints.sol";

contract OrderExecutor is IOrderExecutor {
    struct Policy {
        address validator;
        uint256 policyId;
    }

    mapping(uint256 => Policy) public policies;

    address public userPoints;

    constructor(address _userPoints) {
        userPoints = _userPoints;
    }

    function execute(
        address orderHandler,
        bytes calldata order,
        bytes calldata signature,
        bytes calldata appSig
    ) external {
        // オーダーを実行して、ヘッダーを取得する
        (OrderHeader memory header, OrderReceipt memory receipt) = IOrderHandler(orderHandler).execute(msg.sender, order, signature);

        // ヘッダーを解釈して、ポリシーとの整合性をチェックする
        validatePolicy(
            header,
            receipt,
            appSig
        );
    }

    function validatePolicy(
        OrderHeader memory header,
        OrderReceipt memory receipt,
        bytes calldata appSig
    ) internal {
        Policy memory policy = policies[header.policyId];

        address consumer = IPolicyValidator(policy.validator).validatePolicy(header, appSig);

        // ポイントの消費を行う
        IUserPoints(userPoints).consumePoints(consumer, receipt.points);
    }
}
