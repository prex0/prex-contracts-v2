// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {OrderHeader, OrderReceipt} from "./interfaces/IOrderHandler.sol";
import {IPolicyValidator} from "./interfaces/IPolicyValidator.sol";
import {SignatureVerification} from "../lib/permit2/src/libraries/SignatureVerification.sol";

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
        bytes policyParams;
        bool isActive;
    }

    // ポリシーIDからポリシー情報へのマッピング
    mapping(uint256 => Policy) public policies;

    uint256 policyCounts;

    error InvalidPolicy();
    error InactivePolicy();

    constructor() {
        policyCounts = 0;
    }

    /**
     * @notice ポリシーを登録する
     * @param validator ポリシーバリデータのアドレス
     * @param publicKey アプリ開発者の公開鍵
     * @param owner ポリシーの所有者
     * @return policyId ポリシーID
     */
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
            "",
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
        OrderReceipt memory receipt,
        bytes calldata appSig
    ) internal returns (address consumer) {
        // ポリシーIDに対応するポリシー情報を取得

        if(header.policyId == 0) {
            consumer = header.user;
        } else {
            Policy memory policy = policies[header.policyId];

            if (!policy.isActive) {
                revert InactivePolicy();
            }

            consumer = verifyAppSignature(receipt, policy, appSig);
            
            if (policy.validator != address(0)) {
                // ポリシーバリデータを呼び出してポリシーを検証し、消費者アドレスを取得
                if(!IPolicyValidator(policy.validator).validatePolicy(header, receipt, policy.policyParams, appSig)) {
                    revert InvalidPolicy();
                }
            }
        }
    }

    /**
     * @notice アプリ開発者の署名を検証する
     * @param receipt オーダーの実行結果
     * @param policy ポリシー情報
     * @param appSig アプリ開発者の署名
     * @return アプリ開発者のアドレス
     */
    function verifyAppSignature(
        OrderReceipt memory receipt,
        Policy memory policy,
        bytes calldata appSig
    ) internal view returns (address) {
        SignatureVerification.verify(appSig, receipt.orderHash, policy.publicKey);

        return policy.owner;
    }

}
