// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IOrderExecutor} from "./interfaces/IOrderExecutor.sol";
import {IOrderHandler, OrderHeader, OrderReceipt} from "./interfaces/IOrderHandler.sol";
import {PolicyManager} from "./PolicyManager.sol";

/**
 * @title OrderExecutor
 * @notice オーダーの実行とポリシーの検証を行うコントラクト
 */
contract OrderExecutor is IOrderExecutor, PolicyManager {
    /**
     * @notice コンストラクタ
     * @param _prexPoint ポイント管理コントラクトのアドレス
     */
    constructor(address _prexPoint) PolicyManager(_prexPoint) {
    }

    /**
     * @notice オーダーを実行する関数
     * @param orderHandler オーダーハンドラーのアドレス
     * @param order オーダーデータ
     * @param signature ユーザーの署名
     * @param appSig アプリケーションの署名
     */
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
}
