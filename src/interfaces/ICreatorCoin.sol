// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface ICreatorCoin {
    function issuer() external view returns (address);
    function updateTokenDetails(bytes32 pictureHash, string memory metadata) external;
}
