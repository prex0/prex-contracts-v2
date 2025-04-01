// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {MockToken} from "./MockToken.sol";

contract MockUniversalRouter {
    MockToken public token;

    constructor(address _token) {
        token = MockToken(_token);
    }

    function execute(address to, uint256 amount) external {
        token.mint(to, amount);
    }
}
