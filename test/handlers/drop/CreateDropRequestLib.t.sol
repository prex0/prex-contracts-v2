// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {CreateDropRequest, CreateDropRequestLib} from "../../../src/handlers/drop/CreateDropRequest.sol";
import {OrderInfo} from "../../../src/libraries/OrderInfo.sol";

contract CreateDropRequestLibTest is Test {
    function setUp() public {
        vm.warp(100);
    }

    function testValidateParamsReturnsTrue() public view {
        assertTrue(CreateDropRequestLib.validateParams(createDropRequest(100, 10, 200)));
        assertTrue(CreateDropRequestLib.validateParams(createDropRequest(100, 20, 200)));
    }

    function testValidateParamsReturnsFalse() public view {
        assertFalse(CreateDropRequestLib.validateParams(createDropRequest(100, 15, 200)));
        assertFalse(CreateDropRequestLib.validateParams(createDropRequest(100, 200, 200)));
        assertFalse(CreateDropRequestLib.validateParams(createDropRequest(0, 0, 200)));

        // expiry is in the past
        assertFalse(CreateDropRequestLib.validateParams(createDropRequest(100, 10, 0)));
        assertFalse(CreateDropRequestLib.validateParams(createDropRequest(100, 10, 100)));
        assertFalse(CreateDropRequestLib.validateParams(createDropRequest(100, 10, 100 + 500 days)));
    }
    
    function createDropRequest(uint256 _amount, uint256 _amountPerWithdrawal, uint256 _expiry)
        public
        pure
        returns (CreateDropRequest memory)
    {
        return CreateDropRequest({
            orderInfo: OrderInfo({dispatcher: address(1), policyId: 1, sender: address(2), deadline: 100, nonce: 1}),
            isPrepaid: true,
            token: address(3),
            dropPolicyId: 4,
            publicKey: address(5),
            amount: _amount,
            amountPerWithdrawal: _amountPerWithdrawal,
            expiry: _expiry,
            name: "test"
        });
    }
}
