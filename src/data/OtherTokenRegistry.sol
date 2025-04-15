// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Owned} from "solmate/src/auth/Owned.sol";

contract OtherTokenRegistry is Owned {
    struct Token {
        bytes32 pictureHash;
        bytes metadata;
    }

    mapping(address => Token) public tokens;

    event TokenRegistered(address indexed token);
    event PictureHashUpdated(address indexed token, bytes32 pictureHash);
    event MetadataUpdated(address indexed token, bytes metadata);

    constructor(address _owner) Owned(_owner) {}

    function registerToken(address token) public onlyOwner {
        emit TokenRegistered(token);
    }

    /**
     * @notice Update the profile of the sender
     * @param pictureHash The hash of the picture of the profile
     * @param metadata The metadata of the profile
     */
    function updateToken(address token, bytes32 pictureHash, bytes memory metadata) public {
        _updatePictureHash(token, pictureHash);
        _updateMetadata(token, metadata);
    }

    function updatePictureHash(address token, bytes32 pictureHash) public onlyOwner {
        _updatePictureHash(token, pictureHash);
    }

    function updateMetadata(address token, bytes memory metadata) public onlyOwner {
        _updateMetadata(token, metadata);
    }

    function _updatePictureHash(address token, bytes32 pictureHash) internal {
        tokens[token].pictureHash = pictureHash;

        emit PictureHashUpdated(token, pictureHash);
    }

    function _updateMetadata(address token, bytes memory metadata) internal {
        tokens[token].metadata = metadata;

        emit MetadataUpdated(token, metadata);
    }

    function getToken(address token) public view returns (Token memory) {
        return tokens[token];
    }
}
