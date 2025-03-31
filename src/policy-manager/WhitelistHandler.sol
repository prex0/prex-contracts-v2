// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Owned} from "../../lib/solmate/src/auth/Owned.sol";

/**
 * @title WhitelistHandlerPolicyValidator
 * @notice ホワイトリストに登録されたハンドラーのみがオーダーを実行できる
 */
contract WhitelistHandler is Owned {
    mapping(address => bool) public whitelist;

    event HandlerAdded(address handler);
    event HandlerRemoved(address handler);

    constructor(address _owner) Owned(_owner) {}

    /**
     * @notice ハンドラーをホワイトリストに追加する
     * @param handler ハンドラーのアドレス
     */
    function addHandler(address handler) external onlyOwner {
        whitelist[handler] = true;

        emit HandlerAdded(handler);
    }

    /**
     * @notice ハンドラーをホワイトリストに追加する
     * @param handlers ハンドラーのアドレス
     */
    function addHandlers(address[] memory handlers) external onlyOwner {
        for (uint256 i = 0; i < handlers.length; i += 1) {
            whitelist[handlers[i]] = true;

            emit HandlerAdded(handlers[i]);
        }
    }

    /**
     * @notice ハンドラーをホワイトリストから削除する
     * @param handler ハンドラーのアドレス
     */
    function removeHandler(address handler) external onlyOwner {
        whitelist[handler] = false;

        emit HandlerRemoved(handler);
    }

    /**
     * @notice ハンドラーがホワイトリストに登録されているかどうかを確認する
     * @param handler ハンドラーのアドレス
     * @return ハンドラーがホワイトリストに登録されている場合はtrue、そうでない場合はfalse
     */
    function validateHandler(address handler) internal view returns (bool) {
        if (!whitelist[handler]) {
            return false;
        }

        return true;
    }
}
