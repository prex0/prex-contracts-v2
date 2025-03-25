// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface ITokenRegistry {
    function updateToken(address token, bytes32 pictureHash, string memory metadata) external;
}
