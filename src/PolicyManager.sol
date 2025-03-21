// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {OrderHeader, OrderReceipt} from "./interfaces/IOrderHandler.sol";
import {IPolicyValidator} from "./interfaces/IPolicyValidator.sol";

/**
 * @notice ポリシーの管理をするコントラクト
 * ポリシーの追加、削除、検証を行う 
 */
contract PolicyManager {
    // ポリシー情報を格納する構造体
    struct Policy {
        address validator; // ポリシーバリデータのアドレス
        uint256 policyId; // ポリシーID
        address publicKey;
        address owner;
        bool isActive;
    }

    // ポリシーIDからポリシー情報へのマッピング
    mapping(uint256 => Policy) public policies;

    uint256 policyCounts;

    constructor() {
        policyCounts = 0;
    
    }

    function registerPolicy(
        address validator,
        address publicKey,
        address owner
    ) external returns(uint256 policyId) {
        policyId = policyCounts++;

        policies[policyId] = Policy(
            validator,
            policyId,
            publicKey,
            owner,
            true
        );
    }

    function deregisterPolicy(uint256 policyId) external {
        policies[policyId].isActive = false;
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
