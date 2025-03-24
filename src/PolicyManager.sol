// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {OrderHeader, OrderReceipt} from "./interfaces/IOrderHandler.sol";
import {IPolicyValidator} from "./interfaces/IPolicyValidator.sol";
import {SignatureVerification} from "../lib/permit2/src/libraries/SignatureVerification.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IUserPoints} from "./interfaces/IUserPoints.sol";

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
        uint256 appId;
        bytes policyParams;
        bool isActive;
    }

    struct App {
        uint256 credit;
        address owner;
    }

    // ポリシーIDからポリシー情報へのマッピング
    mapping(uint256 => Policy) public policies;

    mapping(uint256 => App) public apps;

    address public prexPoint;

    uint256 policyCounts;
    uint256 appCounts;

    error InvalidPolicy();
    error InactivePolicy();
    error InvalidAppOwner();
    error InvalidPolicyOwner();
    error InsufficientCredit();

    modifier onlyPolicyOwner(uint256 policyId) {
        if (apps[policies[policyId].appId].owner != msg.sender) {
            revert InvalidPolicyOwner();
        }
        _;
    }

    modifier onlyAppOwner(uint256 appId) {
        if (apps[appId].owner != msg.sender) {
            revert InvalidAppOwner();
        }
        _;
    }

    constructor(address _prexPoint) {
        policyCounts = 0;
        appCounts = 0;
        prexPoint = _prexPoint;
    }

    /**
     * @notice ポリシーを登録する
     * @param validator ポリシーバリデータのアドレス
     * @param publicKey アプリ開発者の公開鍵
     * @param appId アプリID
     * @return policyId ポリシーID
     */
    function registerPolicy(
        address validator,
        address publicKey,
        uint256 appId
    ) external onlyAppOwner(appId) returns(uint256 policyId) {
        policyId = policyCounts++;

        policies[policyId] = Policy(
            validator,
            policyId,
            publicKey,
            appId,
            "",
            true
        );
    }

    function deregisterPolicy(uint256 policyId) external onlyPolicyOwner(policyId) {
        policies[policyId].isActive = false;
    }

    function depositCredit(uint256 appId, uint256 amount) external {
        IERC20(prexPoint).transferFrom(msg.sender, address(this), amount);

        apps[appId].credit += amount;
    }

    function withdrawCredit(uint256 appId, uint256 amount, address to) external onlyAppOwner(appId) {
        if (apps[appId].credit < amount) {
            revert InsufficientCredit();
        }

        apps[appId].credit -= amount;

        IERC20(prexPoint).transfer(to, amount);
    }

    function consumeAppCredit(uint256 appId, uint256 amount) internal {
        if (apps[appId].credit < amount) {
            revert InsufficientCredit();
        }

        apps[appId].credit -= amount;

        IUserPoints(prexPoint).burn(amount);
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
    ) internal {
        // ポリシーIDに対応するポリシー情報を取得

        if(header.policyId == 0) {
            IUserPoints(prexPoint).consumePoints(header.user, receipt.points);
        } else {
            Policy memory policy = policies[header.policyId];

            if (!policy.isActive) {
                revert InactivePolicy();
            }
            
            verifyAppSignature(receipt, policy, appSig);

            consumeAppCredit(policy.appId, receipt.points);

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
     */
    function verifyAppSignature(
        OrderReceipt memory receipt,
        Policy memory policy,
        bytes calldata appSig
    ) internal view {
        SignatureVerification.verify(appSig, receipt.orderHash, policy.publicKey);
    }
}
