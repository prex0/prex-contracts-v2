// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {PolicyPrimitiveSetup} from "./Setup.t.sol";
import {StandardPolicyValidator} from "src/policies/StandardPolicyValidator.sol";
import {OrderHeader} from "src/interfaces/IOrderExecutor.sol";
import {OrderReceipt} from "src/interfaces/IOrderHandler.sol";

contract StandardPolicyValidatorText is PolicyPrimitiveSetup {
    StandardPolicyValidator public standardPolicyValidator;

    address public constant WHITELIST_HANDLER = address(550);
    address public constant WHITELIST_TOKEN = address(650);

    function setUp() public override {
        super.setUp();

        standardPolicyValidator = new StandardPolicyValidator();
    }

    function getOrderReceipt(address token) internal view returns (OrderReceipt memory) {
        address[] memory tokens = new address[](1);

        tokens[0] = token;

        return OrderReceipt({tokens: tokens, user: address(0), policyId: 0, points: 0});
    }

    function test_validatePolicy() public {
        OrderHeader memory header =
            OrderHeader({dispatcher: WHITELIST_HANDLER, methodId: 0, orderHash: bytes32(0), identifier: bytes32(0)});

        OrderReceipt memory receipt = getOrderReceipt(WHITELIST_TOKEN);

        address[] memory whitelist = new address[](1);
        whitelist[0] = WHITELIST_TOKEN;

        bytes memory policyParams = abi.encode(whitelist, 1, 1 days);

        assertTrue(standardPolicyValidator.validatePolicy(header, receipt, policyParams));
        assertFalse(standardPolicyValidator.validatePolicy(header, receipt, policyParams));
    }
}
