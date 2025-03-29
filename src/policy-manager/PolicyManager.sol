// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {OrderReceipt} from "../interfaces/IOrderHandler.sol";
import {OrderHeader} from "../interfaces/IOrderExecutor.sol";
import {IPolicyValidator} from "../interfaces/IPolicyValidator.sol";
import {SignatureVerification} from "../../lib/permit2/src/libraries/SignatureVerification.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {MessageHashUtils} from "../../lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {IPrexPoints} from "../interfaces/IPrexPoints.sol";
import {CreditPrice} from "./CreditPrice.sol";
import {IPolicyErrors} from "../interfaces/IPolicyErrors.sol";

/**
 * @notice ポリシーの管理をするコントラクト
 * ポリシーの追加、削除、検証を行う
 */
contract PolicyManager is CreditPrice, IPolicyErrors {
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
        address owner;
        uint256 credit;
    }

    // ポリシーIDからポリシー情報へのマッピング
    mapping(uint256 => Policy) public policies;

    mapping(uint256 => App) public apps;

    address public prexPoint;

    uint256 policyCounts;
    uint256 appCounts;

    event AppRegistered(uint256 appId, address owner, string appName);
    event PolicyRegistered(
        uint256 appId, uint256 policyId, address validator, address publicKey, bytes policyParams, string policyName
    );
    event PolicyStatusUpdated(uint256 appId, uint256 policyId, bool isActive);

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

    constructor(address _prexPoint, address _owner) CreditPrice(_owner) {
        policyCounts = 1;
        appCounts = 1;
        prexPoint = _prexPoint;
    }

    /**
     * @notice アプリを登録する
     * @param owner アプリのオーナー
     * @param appName アプリの名前
     * @return appId アプリID
     */
    function registerApp(address owner, string calldata appName) external returns (uint256 appId) {
        appId = appCounts++;

        apps[appId] = App({owner: owner, credit: 0});

        emit AppRegistered(appId, owner, appName);
    }

    /**
     * @notice ポリシーを登録する
     * @param validator ポリシーバリデータのアドレス
     * @param publicKey アプリ開発者の公開鍵
     * @param appId アプリID
     * @return policyId ポリシーID
     */
    function registerPolicy(
        uint256 appId,
        address validator,
        address publicKey,
        bytes calldata policyParams,
        string calldata policyName
    ) external onlyAppOwner(appId) returns (uint256 policyId) {
        policyId = policyCounts++;

        policies[policyId] = Policy(validator, policyId, publicKey, appId, policyParams, true);

        emit PolicyRegistered(appId, policyId, validator, publicKey, policyParams, policyName);
    }

    /**
     * @notice ポリシーを削除する
     * @param policyId ポリシーID
     */
    function updatePolicyStatus(uint256 policyId, bool isActive) external onlyPolicyOwner(policyId) {
        policies[policyId].isActive = isActive;

        emit PolicyStatusUpdated(policies[policyId].appId, policyId, isActive);
    }

    /**
     * @notice クレジットをデポジットする
     * @param appId アプリID
     * @param amount デポジットするクレジット量
     */
    function depositCredit(uint256 appId, uint256 amount) external {
        IERC20(prexPoint).transferFrom(msg.sender, address(this), amount);

        apps[appId].credit += amount;
    }

    /**
     * @notice クレジットを引き出す
     * @param appId アプリID
     * @param amount 引き出すクレジット量
     * @param to 引き出す先のアドレス
     */
    function withdrawCredit(uint256 appId, uint256 amount, address to) external onlyAppOwner(appId) {
        if (apps[appId].credit < amount) {
            revert InsufficientCredit();
        }

        apps[appId].credit -= amount;

        IERC20(prexPoint).transfer(to, amount);
    }

    /**
     * @notice ポリシーの検証を行う内部関数
     * @param header オーダーヘッダー
     * @param appSig アプリケーションの署名
     */
    function _validatePolicy(OrderHeader memory header, OrderReceipt memory receipt, bytes calldata appSig) internal {
        // ポリシーIDに対応するポリシー情報を取得
        if (!validateHandler(header.dispatcher)) {
            revert InvalidHandler();
        }

        if (receipt.policyId == 0) {
            IPrexPoints(prexPoint).consumePoints(receipt.user, receipt.points * creditPrice);
        } else {
            Policy memory policy = policies[receipt.policyId];

            if (!policy.isActive) {
                revert InactivePolicy();
            }

            _verifyAppSignature(header, policy, appSig);

            _consumeAppCredit(policy.appId, receipt.points * creditPrice);

            if (policy.validator != address(0)) {
                // ポリシーバリデータを呼び出してポリシーを検証し、消費者アドレスを取得
                if (!IPolicyValidator(policy.validator).validatePolicy(header, receipt, policy.policyParams)) {
                    revert InvalidPolicy();
                }
            }
        }
    }

    /**
     * @notice アプリ開発者の署名を検証する
     * @param header オーダーヘッダー
     * @param policy ポリシー情報
     * @param appSig アプリ開発者の署名
     */
    function _verifyAppSignature(OrderHeader memory header, Policy memory policy, bytes calldata appSig) private view {
        bytes32 messageHash = MessageHashUtils.toEthSignedMessageHash(header.orderHash);

        SignatureVerification.verify(appSig, messageHash, policy.publicKey);
    }

    /**
     * @notice アプリのクレジットを消費する
     * @param appId アプリID
     * @param amount 消費するクレジット量
     */
    function _consumeAppCredit(uint256 appId, uint256 amount) private {
        if (apps[appId].credit < amount) {
            revert InsufficientCredit();
        }

        apps[appId].credit -= amount;

        IPrexPoints(prexPoint).burn(amount);
    }
}
