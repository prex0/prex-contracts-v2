// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {BasePrexToken} from "../base/BasePrexToken.sol";
import {Owned} from "../../lib/solmate/src/auth/Owned.sol";
import {IUserPoints} from "../interfaces/IUserPoints.sol";

/**
 * @notice Prexポイントは、ERC20です。
 * OrderExecutorは、Prexポイントを消費してオーダーを実行します。
 */
contract PrexPoint is IUserPoints, BasePrexToken, Owned {
    address public orderExecutor;

    modifier onlyOrderExecutor() {
        if (msg.sender != orderExecutor) {
            revert("Only order executor can call this function");
        }
        _;
    }

    constructor(address _owner, address _permit2) BasePrexToken("PrexPoint", "PREX", _permit2) Owned(_owner) {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function setOrderExecutor(address _orderExecutor) external onlyOwner {
        orderExecutor = _orderExecutor;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function consumePoints(address user, uint256 points) external onlyOrderExecutor {
        _burn(user, points);
    }
}
