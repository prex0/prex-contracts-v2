// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {BaseCreatorCoin} from "./BaseCreatorCoin.sol";
import {CreateTokenParameters} from "../TokenParams.sol";

/**
 * @notice LoyaltyCoin is a token that can be created by the creator.
 */
contract LoyaltyCoin is BaseCreatorCoin {
    uint256 constant MAX_SUPPLY = 1e27;

    address public immutable minter;

    error MaxSupplyReached();
    error OnlyMinter();

    modifier onlyMinter() {
        if (msg.sender != minter) {
            revert OnlyMinter();
        }
        _;
    }

    /**
     * @notice Constructor
     * @param params The parameters for the token
     * @param _minter The address of the minter
     * @param _permit2 The address of the permit2
     * @param _tokenRegistry The address of the token registry
     */
    constructor(CreateTokenParameters memory params, address _minter, address _permit2, address _tokenRegistry)
        BaseCreatorCoin(params.name, params.symbol, params.issuer, _permit2, _tokenRegistry)
    {
        minter = _minter;

        tokenRegistry.updateToken(address(this), params.pictureHash, params.metadata);
    }

    /**
     * @notice Issuerは、10億枚までmint可能
     * @param to The address to mint the tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyMinter {
        if (totalSupply() + amount > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        _mint(to, amount);
    }

    /**
     * @notice Burn the tokens
     * @param from The address to burn the tokens from
     * @param amount The amount of tokens to burn
     */
    function burn(address from, uint256 amount) external onlyMinter {
        _burn(from, amount);
    }
}
