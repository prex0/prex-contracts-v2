// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IUserPoints {
    function consumePoints(
        address user,
        uint256 points
    ) external;
}
