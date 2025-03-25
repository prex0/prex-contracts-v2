// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ICreatorCoin} from "../interfaces/ICreatorCoin.sol";

contract TokenRegistry {
    struct Token {
        bytes32 pictureHash;
        string metadata;
    }

    mapping(address => Token) public tokens;

    event PictureHashUpdated(address indexed token, bytes32 pictureHash);
    event MetadataUpdated(address indexed token, string metadata);

    error NotIssuer();

    modifier onlyIssuer(address token) {
        if (ICreatorCoin(token).issuer() != msg.sender && token != msg.sender) {
            revert NotIssuer();
        }
        _;
    }

    /**
     * @notice Update the profile of the sender
     * @param pictureHash The hash of the picture of the profile
     * @param metadata The metadata of the profile
     */
    function updateToken(address token, bytes32 pictureHash, string memory metadata) public {
        _updatePictureHash(token, pictureHash);
        _updateMetadata(token, metadata);
    }

    function updatePictureHash(address token, bytes32 pictureHash) public onlyIssuer(token) {
        _updatePictureHash(token, pictureHash);
    }

    function updateMetadata(address token, string memory metadata) public onlyIssuer(token) {
        _updateMetadata(token, metadata);
    }

    function _updatePictureHash(address token, bytes32 pictureHash) internal {
        tokens[token].pictureHash = pictureHash;

        emit PictureHashUpdated(token, pictureHash);
    }

    function _updateMetadata(address token, string memory metadata) internal {
        tokens[token].metadata = metadata;

        emit MetadataUpdated(token, metadata);
    }

    function getToken(address token) public view returns (Token memory) {
        return tokens[token];
    }
}
