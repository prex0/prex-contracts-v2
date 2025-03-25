// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IPolicyValidator} from "../interfaces/IPolicyValidator.sol";
import {SignatureVerification} from "../../lib/permit2/src/libraries/SignatureVerification.sol";
import {OrderReceipt} from "../interfaces/IOrderHandler.sol";
import {OrderHeader} from "../interfaces/IOrderExecutor.sol";

/**
 * @title WhitelistTokenPolicyValidator
 * @notice ホワイトリストに登録されたトークンのみがオーダーを実行できる
 */
contract WhitelistTokenPolicyValidator is IPolicyValidator {
    error InvalidToken();

    function validatePolicy(
        OrderHeader memory header,
        OrderReceipt memory receipt,
        bytes memory policyParams,
        bytes calldata _appParams
    ) external returns (bool) {
        address[] memory whitelist = abi.decode(policyParams, (address[]));

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
