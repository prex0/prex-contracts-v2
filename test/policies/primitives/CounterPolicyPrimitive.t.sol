// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {CounterPolicyPrimitive} from "src/policies/primitives/CounterPolicyPrimitive.sol";

contract CounterPolicyPrimitiveWrapper is CounterPolicyPrimitive {
    function validateCounter(uint256 policyId, bytes32 identifier, uint256 dailyLimit, uint256 timeUnit)
        external
        returns (bool)
    {
        return _validateCounter(policyId, identifier, dailyLimit, timeUnit);
    }
}

contract CounterPolicyPrimitiveTest is Test {
    CounterPolicyPrimitiveWrapper public counterPolicyPrimitive;

    uint256 public policyId = 1;
    bytes32 public identifier1 = bytes32(uint256(1));
    bytes32 public identifier2 = bytes32(uint256(2));

    function setUp() public {
        counterPolicyPrimitive = new CounterPolicyPrimitiveWrapper();
    }

    // 1日に1回だけオーダーを実行できる
    function test_validateCounter_1_per_day() public {
        assertTrue(counterPolicyPrimitive.validateCounter(policyId, identifier1, 1, 1 days));
        assertFalse(counterPolicyPrimitive.validateCounter(policyId, identifier1, 1, 1 days));

        // 他のidentifierのオーダーは実行できる
        assertTrue(counterPolicyPrimitive.validateCounter(policyId, identifier2, 1, 1 days));

        vm.warp(block.timestamp + 1 days);

        // 1日経過したらカウンターがリセットされる
        assertTrue(counterPolicyPrimitive.validateCounter(policyId, identifier1, 1, 1 days));
    }

    // 1回だけオーダーを実行できる
    function test_validateCounter_1() public {
        assertTrue(counterPolicyPrimitive.validateCounter(policyId, identifier1, 1, 10000 days));
        assertFalse(counterPolicyPrimitive.validateCounter(policyId, identifier1, 1, 10000 days));

        // 他のidentifierのオーダーは実行できる
        assertTrue(counterPolicyPrimitive.validateCounter(policyId, identifier2, 1, 10000 days));

        vm.warp(block.timestamp + 10 days);

        // 10日経過しても、カウンターがリセットされない
        assertFalse(counterPolicyPrimitive.validateCounter(policyId, identifier1, 1, 10000 days));
    }

    // 1日に3回だけオーダーを実行できる
    function test_validateCounter_3_per_day() public {
        assertTrue(counterPolicyPrimitive.validateCounter(policyId, identifier1, 3, 1 days));
        assertTrue(counterPolicyPrimitive.validateCounter(policyId, identifier1, 3, 1 days));
        assertTrue(counterPolicyPrimitive.validateCounter(policyId, identifier1, 3, 1 days));
        assertFalse(counterPolicyPrimitive.validateCounter(policyId, identifier1, 3, 1 days));

        vm.warp(block.timestamp + 1 days);

        // 1日経過したらカウンターがリセットされる
        assertTrue(counterPolicyPrimitive.validateCounter(policyId, identifier1, 3, 1 days));
    }
}
