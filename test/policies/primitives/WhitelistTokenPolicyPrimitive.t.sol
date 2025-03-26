// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {WhitelistTokenPolicyPrimitive} from "src/policies/primitives/WhitelistTokenPolicyPrimitive.sol";

contract WhitelistTokenPolicyPrimitiveWrapper is WhitelistTokenPolicyPrimitive {
    function validateTokens(address[] memory tokens, address[] memory whitelist) external pure returns (bool) {
        return _validateTokens(tokens, whitelist);
    }
}

contract WhitelistTokenPolicyPrimitiveTest is Test {
    WhitelistTokenPolicyPrimitiveWrapper public whitelistTokenPolicyPrimitive;

    address public token1 = address(1);
    address public token2 = address(2);
    address public token3 = address(3);

    address[] public whitelist = [token1, token2];

    address[] public tokenRequest1 = new address[](0);
    address[] public tokenRequest2 = [token1];
    address[] public tokenRequest3 = [token1, token2];
    address[] public tokenRequest4 = [token2];
    address[] public tokenRequest5 = [token3];
    address[] public tokenRequest6 = [token1, token3];

    function setUp() public {
        whitelistTokenPolicyPrimitive = new WhitelistTokenPolicyPrimitiveWrapper();
    }

    function test_validateTokens() public {
        // Truthy cases

        // [] in [1, 2]
        assertTrue(whitelistTokenPolicyPrimitive.validateTokens(tokenRequest1, whitelist));
        // [1] in [1, 2]
        assertTrue(whitelistTokenPolicyPrimitive.validateTokens(tokenRequest2, whitelist));
        // [1, 2] in [1, 2]
        assertTrue(whitelistTokenPolicyPrimitive.validateTokens(tokenRequest3, whitelist));
        // [2] in [1, 2]
        assertTrue(whitelistTokenPolicyPrimitive.validateTokens(tokenRequest4, whitelist));

        // Falsy cases

        // [3] in [1, 2]
        assertFalse(whitelistTokenPolicyPrimitive.validateTokens(tokenRequest5, whitelist));
        // [1, 3] in [1, 2]
        assertFalse(whitelistTokenPolicyPrimitive.validateTokens(tokenRequest6, whitelist));
    }
}
