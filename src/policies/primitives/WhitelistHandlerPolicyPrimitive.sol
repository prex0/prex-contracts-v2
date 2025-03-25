// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {OrderReceipt} from "../../interfaces/IOrderHandler.sol";
import {OrderHeader} from "../../interfaces/IOrderExecutor.sol";
import {Owned} from "../../../lib/solmate/src/auth/Owned.sol";

/**
 * @title WhitelistHandlerPolicyValidator
 * @notice ホワイトリストに登録されたハンドラーのみがオーダーを実行できる
 */
contract WhitelistHandlerPolicyPrimitive is Owned {
    mapping(address => bool) public whitelist;

    constructor(address _owner) Owned(_owner) {}

    /**
     * @notice ハンドラーをホワイトリストに追加する
     * @param handler ハンドラーのアドレス
     */
    function addHandler(address handler) external onlyOwner {
        whitelist[handler] = true;
    }

    /**
     * @notice ハンドラーをホワイトリストに追加する
     * @param handlers ハンドラーのアドレス
     */
    function addHandlers(address[] memory handlers) external onlyOwner {
        for (uint256 i = 0; i < handlers.length; i += 1) {
            whitelist[handlers[i]] = true;
        }
    }

    /**
     * @notice ハンドラーをホワイトリストから削除する
     * @param handler ハンドラーのアドレス
     */
    function removeHandler(address handler) external onlyOwner {
        whitelist[handler] = false;
    }

    function validate(OrderHeader memory header) external view returns (bool) {
        if (!whitelist[header.dispatcher]) {
            return false;
        }

        return true;
    }
}
