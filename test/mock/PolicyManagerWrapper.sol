// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {PolicyManager} from "../../src/policy-manager/PolicyManager.sol";
import {OrderHeader} from "../../src/interfaces/IOrderExecutor.sol";
import {OrderReceipt} from "../../src/interfaces/IOrderHandler.sol";

/**
 * @notice テスト用のOrderExecutor
 */
contract PolicyManagerWrapper is PolicyManager {
    /**
     * @notice コンストラクタ
     * @param _prexPoint ポイント管理コントラクトのアドレス
     */
    constructor(address _prexPoint, address _owner) PolicyManager(_prexPoint, _owner) {}

    function validatePolicy(OrderHeader memory header, OrderReceipt memory receipt, bytes calldata appSig) external {
        _validatePolicy(header, receipt, appSig);
    }
}
