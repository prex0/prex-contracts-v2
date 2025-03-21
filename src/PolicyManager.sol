// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {OrderHeader, OrderReceipt} from "./interfaces/IOrderHandler.sol";
import {IPolicyValidator} from "./interfaces/IPolicyValidator.sol";

contract PolicyManager {
    // ポリシー情報を格納する構造体
    struct Policy {
        address validator; // ポリシーバリデータのアドレス
        uint256 policyId; // ポリシーID
    }

    // ポリシーIDからポリシー情報へのマッピング
    mapping(uint256 => Policy) public policies;

    function registerPolicy() external returns(uint256 pocilyId) {

    }

    function deregisterPolicy(uint256 policyId) external {

    }

    /**
     * @notice ポリシーの検証を行う内部関数
     * @param header オーダーヘッダー
     * @param appSig アプリケーションの署名
     */
    function validatePolicy(
        OrderHeader memory header,
        bytes calldata appSig
    ) internal view returns (address consumer) {
        // ポリシーIDに対応するポリシー情報を取得
        Policy memory policy = policies[header.policyId];

        // ポリシーバリデータを呼び出してポリシーを検証し、消費者アドレスを取得
        consumer = IPolicyValidator(policy.validator).validatePolicy(header, appSig);
    }
}
