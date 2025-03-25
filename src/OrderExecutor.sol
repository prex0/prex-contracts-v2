// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IOrderExecutor, OrderHeader} from "./interfaces/IOrderExecutor.sol";
import {IOrderHandler, OrderReceipt, SignedOrder} from "./interfaces/IOrderHandler.sol";
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
        // オーダーを実行して、注文結果を取得する
        OrderReceipt memory receipt = IOrderHandler(order.dispatcher).execute(msg.sender, order, facilitatorData);

        // ヘッダーを解釈して、ポリシーとの整合性をチェックする
        validatePolicy(
            OrderHeader({
                dispatcher: order.dispatcher,
                methodId: order.methodId,
                orderHash: _getOrderHashForPolicy(order),
                identifier: order.identifier
            }),
            receipt,
            order.appSig
        );
    }

    function _getOrderHashForPolicy(SignedOrder calldata order) internal pure returns (bytes32) {
        return keccak256(abi.encode("AppOrder", order.order, order.identifier));
    }
}
