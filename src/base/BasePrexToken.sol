// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
 * @notice BaseCreatorCoin is a base contract for CreatorCoin.
 */
abstract contract BasePrexToken is ERC20Permit {
    address public immutable permit2;

    constructor(string memory _name, string memory _symbol, address _permit2)
        ERC20(_name, _symbol)
        ERC20Permit(_name)
    {
        permit2 = _permit2;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        // permit2 can spend any amount
        if (spender == permit2) {
            return type(uint256).max;
        }
        return super.allowance(owner, spender);
    }
}
