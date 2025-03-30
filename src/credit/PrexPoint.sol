// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {BasePrexToken} from "../base/BasePrexToken.sol";
import {Owned} from "../../lib/solmate/src/auth/Owned.sol";
import {IPrexPoints} from "../interfaces/IPrexPoints.sol";

/**
 * @notice Prexポイントは、ERC20です。
 * ownerは、ポイントを発行します。
 * consumerは、ポイントを消費します。
 */
contract PrexPoint is IPrexPoints, BasePrexToken, Owned {
    /// @dev ポイントを消費できるコントラクト
    address public consumer;

    modifier onlyConsumer() {
        if (msg.sender != consumer) {
            revert("Only consumer can call this function");
        }
        _;
    }

    constructor(string memory name, string memory symbol, address _owner, address _permit2)
        BasePrexToken(name, symbol, _permit2)
        Owned(_owner)
    {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function setConsumer(address _consumer) external onlyOwner {
        consumer = _consumer;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function consumePoints(address user, uint256 points) external onlyConsumer {
        _burn(user, points);
    }
}
