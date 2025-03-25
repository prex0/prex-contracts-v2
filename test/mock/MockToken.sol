// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
 * @notice MockToken
 */
contract MockToken is ERC20 {
    constructor() ERC20("MockToken", "MT") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
