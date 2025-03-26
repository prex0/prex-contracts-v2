// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {SafeCastLib} from "../../../lib/solmate/src/utils/SafeCastLib.sol";

/**
 * @title CounterPolicyValidator
 * @notice 1日に、n回だけオーダーを実行できる
 */
abstract contract CounterPolicyPrimitive {
    using SafeCastLib for uint256;

    struct Counter {
        uint128 counter;
        uint128 lastExecutionDay;
    }
    // カウンター

    mapping(uint256 policyId => mapping(bytes32 identifier => Counter)) public counterMap;

    function _validateCounter(uint256 policyId, bytes32 identifier, uint256 dailyLimit, uint256 timeUnit)
        internal
        returns (bool)
    {
        uint256 currentDay = block.timestamp / timeUnit;

        Counter storage counter = counterMap[policyId][identifier];

        if (counter.lastExecutionDay < currentDay) {
            counter.counter = 0;
            counter.lastExecutionDay = currentDay.safeCastTo128();
        }

        if (counter.counter >= dailyLimit) {
            return false;
        }

        counter.counter++;

        return true;
    }
}
