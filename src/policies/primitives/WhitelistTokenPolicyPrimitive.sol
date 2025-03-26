// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {OrderReceipt} from "../../interfaces/IOrderHandler.sol";
import {OrderHeader} from "../../interfaces/IOrderExecutor.sol";

/**
 * @title WhitelistTokenPolicyValidator
 * @notice ホワイトリストに登録されたトークンのみがオーダーを実行できる
 */
abstract contract WhitelistTokenPolicyPrimitive {
    error InvalidToken();

    function validateTokens(OrderReceipt memory receipt, address[] memory whitelist) internal pure returns (bool) {
        for (uint256 i = 0; i < receipt.tokens.length; i += 1) {
            address tokenAddress = receipt.tokens[i];

            if (!_isInWhitelist(whitelist, tokenAddress)) {
                revert InvalidToken();
            }
        }

        return true;
    }

    function _isInWhitelist(address[] memory whitelist, address tokenAddress) internal pure returns (bool) {
        for (uint256 i = 0; i < whitelist.length; i += 1) {
            if (whitelist[i] == tokenAddress) {
                return true;
            }
        }

        return false;
    }
}
