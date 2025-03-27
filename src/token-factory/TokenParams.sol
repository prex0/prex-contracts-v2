// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

struct CreateTokenParameters {
    address issuer;
    address recipient;
    uint256 initialSupply;
    string name;
    string symbol;
    bytes32 pictureHash;
    string metadata;
}
