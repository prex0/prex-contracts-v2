// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IUserPoints} from "./interfaces/IUserPoints.sol";

/**
 * @notice Prexポイントは、ERC20です。
 * OrderExecutorは、Prexポイントを消費することができます。
 */
contract PrexPoint is IUserPoints, ERC20 {
    constructor() ERC20("PrexPoint", "PREX", 18) {}
    function consumePoints(
        address user,
        uint256 points
    ) external {
    }
}