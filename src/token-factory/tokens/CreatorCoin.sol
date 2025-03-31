// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {BaseCreatorCoin} from "./BaseCreatorCoin.sol";
import {CreateTokenParameters} from "../TokenParams.sol";

/**
 * @notice CreatorCoin is a token that can be created by the creator.
 */
contract CreatorCoin is BaseCreatorCoin {
    constructor(CreateTokenParameters memory params, address _permit2, address _tokenRegistry)
        BaseCreatorCoin(params.name, params.symbol, params.issuer, _permit2, _tokenRegistry)
    {
        _mint(params.recipient, params.initialSupply);

        tokenRegistry.updateToken(address(this), params.pictureHash, params.metadata);
    }
}
