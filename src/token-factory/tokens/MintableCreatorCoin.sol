// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {BaseCreatorCoin} from "./BaseCreatorCoin.sol";

/**
 * @notice MintableCreatorCoin is a token that can be created by the creator.
 */
contract MintableCreatorCoin is BaseCreatorCoin {
    uint256 constant MAX_SUPPLY = 1e27;

    error MaxSupplyReached();

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _recipient,
        address _issuer,
        address _permit2,
        address _tokenRegistry
    ) BaseCreatorCoin(_name, _symbol, _issuer, _permit2, _tokenRegistry) {
        if (_initialSupply > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        _mint(_recipient, _initialSupply);
    }

    /**
     * @notice Issuerは、10億枚までmint可能
     * @param to The address to mint the tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyIssuer {
        if (totalSupply() + amount > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        _mint(to, amount);
    }
}
