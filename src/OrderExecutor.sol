// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IOrderExecutor} from "./interfaces/IOrderExecutor.sol";
import {IOrderHandler, OrderHeader, OrderReceipt, SignedOrder} from "./interfaces/IOrderHandler.sol";
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
    constructor(address _prexPoint) PolicyManager(_prexPoint) {}

    /**
     * @notice オーダーを実行する関数
     * @param order オーダーデータ
     * @param facilitatorData ファシリテーターのデータ
     */
    function execute(SignedOrder calldata order, bytes calldata facilitatorData) external {
        // オーダーを実行して、ヘッダーを取得する
        (OrderHeader memory header, OrderReceipt memory receipt) =
            IOrderHandler(order.dispatcher).execute(msg.sender, order);

        // ヘッダーを解釈して、ポリシーとの整合性をチェックする
        validatePolicy(header, receipt, order.appSig);
    }
}
