// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20Permit} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Owned} from "../../lib/solmate/src/auth/Owned.sol";
import {IUserPoints} from "../interfaces/IUserPoints.sol";

/**
 * @notice Prexポイントは、ERC20です。
 * OrderExecutorは、Prexポイントを消費してオーダーを実行します。
 */
contract PrexPoint is IUserPoints, ERC20Permit, Owned {
    address public permit2;
    address public orderExecutor;

    modifier onlyOrderExecutor() {
        if (msg.sender != orderExecutor) {
            revert("Only order executor can call this function");
        }
        _;
    }

    constructor(address _owner, address _permit2) ERC20("PrexPoint", "PREX") ERC20Permit("PrexPoint") Owned(_owner) {
        permit2 = _permit2;
    }

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

    function allowance(address owner, address spender) public view override returns (uint256) {
        // permit2 can spend any amount
        if (spender == permit2) {
            return type(uint256).max;
        }
        return super.allowance(owner, spender);
    }
}
