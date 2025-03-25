// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {BaseCreatorCoin} from "./BaseCreatorCoin.sol";

/**
 * @notice CreatorCoin is a token that can be created by the creator.
 */
contract CreatorCoin is BaseCreatorCoin {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _recipient,
        address _issuer,
        address _permit2,
        address _tokenRegistry
    ) BaseCreatorCoin(_name, _symbol, _issuer, _permit2, _tokenRegistry) {
        _mint(_recipient, _initialSupply);
    }
}
