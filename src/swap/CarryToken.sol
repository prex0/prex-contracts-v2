// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {Owned} from "solmate/src/auth/Owned.sol";

/**
 * PumPumのCreatorCoinとPointを媒介するためのToken
 */
contract CarryToken is ERC20, Owned {
    constructor(address _owner) ERC20("CarryToken", "CARRY", 6) Owned(_owner) {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
