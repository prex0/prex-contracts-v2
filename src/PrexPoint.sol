// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {Owned} from "../lib/solmate/src/auth/Owned.sol";
import {IUserPoints} from "./interfaces/IUserPoints.sol";

/**
 * @notice Prexポイントは、ERC20です。
 * OrderExecutorは、Prexポイントを消費することができます。
 */
contract PrexPoint is IUserPoints, ERC20, Owned {
    address public permit2;

    constructor(address _owner, address _permit2) ERC20("PrexPoint", "PREX", 18) Owned(_owner) {
        permit2 = _permit2;
    }

    function consumePoints(
        address user,
        uint256 points
    ) external onlyOwner {
        _burn(user, points);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        // permit2 can spend any amount
        if (spender == permit2) {
            return type(uint256).max;
        }
        return super.allowance(owner, spender);
    }
}
