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
        bool isActive;
    }

    /// @dev ポリシーIDからポリシー情報へのマッピング
    mapping(uint256 policyId => Policy) public policies;

    /// @dev アプリIDからアプリ情報へのマッピング
    mapping(uint256 appId => App) public apps;

    /// @dev クレジットを管理するトークンのアドレス
    address public prexPoint;

    /// @dev ポリシーの数
    uint256 public nextPolicyId = 1;

    /// @dev アプリの数
    uint256 public nextAppId = 1;

    event AppRegistered(uint256 appId, address owner, string appName);
    event AppStatusUpdated(uint256 appId, bool isActive);
    event PolicyRegistered(
        uint256 appId, uint256 policyId, address validator, address publicKey, bytes policyParams, string policyName
    );
    event PolicyStatusUpdated(uint256 appId, uint256 policyId, bool isActive);
    event CreditDeposited(uint256 appId, uint256 amount);
    event CreditWithdrawn(uint256 appId, uint256 amount);
    event CreditConsumed(uint256 appId, uint256 amount);

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
        prexPoint = _prexPoint;
    }

    /**
     * @notice アプリを登録する
     * @param owner アプリのオーナー
     * @param appName アプリの名前
     * @return appId アプリID
     */
    function registerApp(address owner, string calldata appName) external returns (uint256 appId) {
        appId = nextAppId++;

        apps[appId] = App({owner: owner, credit: 0, isActive: true});

        emit AppRegistered(appId, owner, appName);
    }

    /**
     * @notice ポリシーを登録する
     * @dev アプリのオーナーのみが登録できる
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
        policyId = nextPolicyId++;

        policies[policyId] = Policy(validator, policyId, publicKey, appId, policyParams, true);

        emit PolicyRegistered(appId, policyId, validator, publicKey, policyParams, policyName);
    }

    /**
     * @notice アプリのステータスを更新する
     * @dev アプリのオーナーのみが更新できる
     * @param appId アプリID
     * @param isActive アプリのステータス
     */
    function updateAppStatus(uint256 appId, bool isActive) external onlyAppOwner(appId) {
        apps[appId].isActive = isActive;

        emit AppStatusUpdated(appId, isActive);
    }

    /**
     * @notice ポリシーを削除する
     * @dev ポリシーのオーナーのみが削除できる
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

        emit CreditDeposited(appId, amount);
    }

    /**
     * @notice クレジットを引き出す
     * @dev アプリのオーナーのみが引き出せる
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

        emit CreditWithdrawn(appId, amount);
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
            // ポリシーIDが0の場合、ユーザのクレジットを消費する
            if (receipt.points > 0) {
                IPrexPoints(prexPoint).consumePoints(receipt.user, receipt.points * creditPrice);
            }
        } else {
            // ポリシーが設定されている場合、アプリ署名を検証し、クレジットを消費する
            Policy memory policy = policies[receipt.policyId];

            if (!policy.isActive) {
                revert InactivePolicy();
            }

            if (!apps[policy.appId].isActive) {
                revert InactiveApp();
            }

            _verifyAppSignature(header, policy, appSig);

            if (receipt.points > 0) {
                _consumeAppCredit(policy.appId, receipt.points * creditPrice);
            }

            // 追加のポリシーバリデーションを実行する
            if (policy.validator != address(0)) {
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

        emit CreditConsumed(appId, amount);
    }
}
