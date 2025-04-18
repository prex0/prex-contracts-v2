// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IOrderExecutor, OrderHeader} from "./interfaces/IOrderExecutor.sol";
import {IOrderHandler, OrderReceipt, SignedOrder} from "./interfaces/IOrderHandler.sol";
import {PolicyManager} from "./policy-manager/PolicyManager.sol";

/**
 * @title OrderExecutor
 * @notice オーダーの実行とポリシーの検証を行うコントラクト
 */
contract OrderExecutor is IOrderExecutor, PolicyManager {
    event OrderExecuted(address indexed facilitator, OrderHeader header, OrderReceipt receipt);

    /**
     * @notice コンストラクタ
     * @param _prexPoint ポイント管理コントラクトのアドレス
     */
    function initialize(address _prexPoint, address _owner) external initializer {
        __PolicyManager_init(_prexPoint, _owner);
    }

    /**
     * @notice オーダーを実行する関数
     * @param order オーダーデータ
     * @param facilitatorData ファシリテーターのデータ
     */
    function execute(SignedOrder calldata order, bytes calldata facilitatorData)
        external
        returns (OrderReceipt memory)
    {
        return _execute(order, facilitatorData);
    }

    /**
     * @notice オーダーをバッチで実行する関数
     * @param orders オーダーデータ
     * @param facilitatorData ファシリテーターのデータ
     */
    function executeBatch(SignedOrder[] calldata orders, bytes[] calldata facilitatorData)
        external
        returns (OrderReceipt[] memory)
    {
        OrderReceipt[] memory receipts = new OrderReceipt[](orders.length);
        for (uint256 i = 0; i < orders.length; i += 1) {
            receipts[i] = _execute(orders[i], facilitatorData[i]);
        }
        return receipts;
    }

    /**
     * @notice オーダーを実行する関数
     * @param order オーダーデータ
     * @param facilitatorData ファシリテーターのデータ
     */
    function _execute(SignedOrder calldata order, bytes calldata facilitatorData)
        internal
        returns (OrderReceipt memory)
    {
        // オーダーを実行して、注文結果を取得する
        OrderReceipt memory receipt = IOrderHandler(order.dispatcher).execute(msg.sender, order, facilitatorData);

        OrderHeader memory header = OrderHeader({
            dispatcher: order.dispatcher,
            methodId: order.methodId,
            orderHash: keccak256(order.order),
            identifier: order.identifier
        });

        // ヘッダーを解釈して、ポリシーとの整合性をチェックする
        _validatePolicy(header, receipt, order.appSig);

        emit OrderExecuted(msg.sender, header, receipt);

        return receipt;
    }
}
