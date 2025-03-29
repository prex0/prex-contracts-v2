// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {CreateTokenParameters} from "../token-factory/TokenParams.sol";
import {CreatorCoin} from "../token-factory/tokens/CreatorCoin.sol";

contract PumController {
    event CreatorCoinCreated(address indexed token);

    mapping(address => address) public creatorTokens;

    //
    function issuePumToken() external {
        // Issue PUM token
        // provide liquidity to PUM/INT pool
        // TODO: Implement swap logic
    }

    /**
     * @notice Create a creator token
     * pumpumの推しの証を作成する
     * @param params トークンのパラメータ
     * @param _permit2 The permit2 address
     * @param _tokenRegistry The token registry address
     * @return The address of the created token
     */
    function createCreatorToken(CreateTokenParameters memory params, address _permit2, address _tokenRegistry)
        public
        returns (address)
    {
        CreatorCoin coin = new CreatorCoin(params, _permit2, _tokenRegistry);

        creatorTokens[address(coin)] = address(coin);

        emit CreatorCoinCreated(address(coin));

        return address(coin);
    }
}
