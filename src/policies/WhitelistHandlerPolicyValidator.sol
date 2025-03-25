// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IPolicyValidator} from "../interfaces/IPolicyValidator.sol";
import {SignatureVerification} from "../../lib/permit2/src/libraries/SignatureVerification.sol";
import {OrderHeader, OrderReceipt} from "../interfaces/IOrderHandler.sol";
import {Owned} from "../../lib/solmate/src/auth/Owned.sol";

/**
 * @title WhitelistHandlerPolicyValidator
 * @notice ホワイトリストに登録されたハンドラーのみがオーダーを実行できる
 */
contract WhitelistHandlerPolicyValidator is IPolicyValidator, Owned {
    mapping(address => bool) public whitelist;

    error InvalidHandler();

    constructor(address _owner) Owned(_owner) {}

    function addHandler(address handler) external onlyOwner {
        whitelist[handler] = true;
    }

    function removeHandler(address handler) external onlyOwner {
        whitelist[handler] = false;
    }

    function validatePolicy(
        OrderHeader memory header,
        OrderReceipt memory receipt,
        bytes memory policyParams,
        bytes calldata _appParams
    ) external returns (bool) {
        if (!whitelist[receipt.dispatcher]) {
            revert InvalidHandler();
        }

        return true;
    }
}
