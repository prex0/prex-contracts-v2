// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {OrderReceipt} from "./IOrderHandler.sol";
import {OrderHeader} from "./IOrderExecutor.sol";

interface IPolicyValidator {
    function validatePolicy(
        // オーダーヘッダー
        OrderHeader memory header,
        // オーダーの実行結果
        OrderReceipt memory receipt,
        // ポリシーのパラメータ
        bytes memory policyParams
    ) external returns (bool);
}
