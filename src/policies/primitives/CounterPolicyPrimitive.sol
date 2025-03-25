// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {OrderReceipt} from "../../interfaces/IOrderHandler.sol";
import {OrderHeader} from "../../interfaces/IOrderExecutor.sol";

/**
 * @title CounterPolicyValidator
 * @notice 1日に、n回だけオーダーを実行できる
 */
contract CounterPolicyPrimitive {
    struct Counter {
        uint256 counter;
        uint256 lastExecutionDay;
    }
    // カウンター

    mapping(address => mapping(bytes32 => Counter)) public counterMap;

    function validateCounter(OrderHeader memory header, uint256 dailyLimit, uint256 timeUnit) internal returns (bool) {
        uint256 currentDay = block.timestamp / timeUnit;

        Counter storage counter = counterMap[header.dispatcher][header.identifier];

        if (counter.lastExecutionDay < currentDay) {
            counter.counter = 0;
            counter.lastExecutionDay = currentDay;
        }

        if (counter.counter >= dailyLimit) {
            return false;
        }

        counter.counter++;

        return true;
    }
}
