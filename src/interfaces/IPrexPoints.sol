// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IPrexPoints {
    function consumePoints(address user, uint256 points) external;

    function burn(uint256 amount) external;

    function mint(address to, uint256 amount) external;
}
