// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Owned} from "solmate/src/auth/Owned.sol";

/**
 * @notice BaseHandler is a base contract for Handler.
 */
abstract contract BaseHandler is Owned {
    address public orderExecutor;

    uint256 public points = 5;

    error CallerMustBeOrderExecutor();

    modifier onlyOrderExecutor() {
        if (msg.sender != orderExecutor) {
            revert CallerMustBeOrderExecutor();
        }
        _;
    }

    constructor(address _owner) Owned(_owner) {}

    /**
     * @notice オーダー実行者を設定する
     * @param _orderExecutor オーダー実行者
     */
    function setOrderExecutor(address _orderExecutor) external onlyOwner {
        orderExecutor = _orderExecutor;
    }

    /**
     * @notice ポイントを設定する
     * @param _points ポイント
     */
    function setPoints(uint256 _points) external onlyOwner {
        points = _points;
    }
}
