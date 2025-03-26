// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IPolicyValidator} from "../interfaces/IPolicyValidator.sol";
import {SignatureVerification} from "../../lib/permit2/src/libraries/SignatureVerification.sol";
import {OrderReceipt} from "../interfaces/IOrderHandler.sol";
import {OrderHeader} from "../interfaces/IOrderExecutor.sol";
import {CounterPolicyPrimitive} from "./primitives/CounterPolicyPrimitive.sol";
import {WhitelistTokenPolicyPrimitive} from "./primitives/WhitelistTokenPolicyPrimitive.sol";

/**
 * @title StandardPolicyValidator
 * @notice handlerとトークンをチェックする
 */
contract StandardPolicyValidator is IPolicyValidator, WhitelistTokenPolicyPrimitive, CounterPolicyPrimitive {
    function validatePolicy(OrderHeader memory header, OrderReceipt memory receipt, bytes memory policyParams)
        external
        returns (bool)
    {
        (address[] memory whitelist, uint256 dailyLimit, uint256 timeUnit) =
            abi.decode(policyParams, (address[], uint256, uint256));

        if (!_validateTokens(receipt.tokens, whitelist)) {
            return false;
        }

        if (!_validateCounter(receipt.policyId, header.identifier, dailyLimit, timeUnit)) {
            return false;
        }

        return true;
    }
}
