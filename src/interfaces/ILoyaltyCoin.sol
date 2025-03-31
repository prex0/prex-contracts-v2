// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface ILoyaltyCoin {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}
