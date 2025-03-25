// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IPolicyValidator} from "../interfaces/IPolicyValidator.sol";
import {SignatureVerification} from "../../lib/permit2/src/libraries/SignatureVerification.sol";
import {OrderHeader, OrderReceipt} from "../interfaces/IOrderHandler.sol";

/**
 * @title CounterPolicyValidator
 * @notice 1日に、n回だけオーダーを実行できる
 */
contract PolicyValidatorV1 is IPolicyValidator {
    struct Counter {
        uint256 counter;
        uint256 lastExecutionDay;
    }
    // カウンター

    mapping(address => mapping(address => Counter)) public counterMap;

    error ExceededDailyLimit();

    function validatePolicy(
        OrderHeader memory header,
        OrderReceipt memory receipt,
        bytes memory policyParams,
        bytes calldata _appParams
    ) external returns (bool) {
        (uint256 dailyLimit, uint256 timeUnit) = abi.decode(policyParams, (uint256, uint256));

        uint256 currentDay = block.timestamp / timeUnit;

        Counter storage counter = counterMap[receipt.dispatcher][header.user];

        if (counter.lastExecutionDay < currentDay) {
            counter.counter = 0;
            counter.lastExecutionDay = currentDay;
        }

        if (counter.counter >= dailyLimit) {
            revert ExceededDailyLimit();
        }

        counter.counter++;

        return true;
    }
}
