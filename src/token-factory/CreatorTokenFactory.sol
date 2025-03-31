// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./tokens/MintableCreatorCoin.sol";
import "./tokens/CreatorCoin.sol";
import "./tokens/LoyaltyCoin.sol";
import "./TokenParams.sol";

/**
 * @notice Creator token factory
 */
contract CreatorTokenFactory {
    event CreatorTokenCreated(address indexed token);

    mapping(address => address) public creatorTokens;

    /**
     * @notice Create a creator token
     * pumpumの推しの証を作成する
     * @param params トークンのパラメータ
     * @param _permit2 The permit2 address
     * @param _tokenRegistry The token registry address
     * @return The address of the created token
     */
    function createCreatorToken(CreateTokenParameters memory params, address _permit2, address _tokenRegistry)
        external
        returns (address)
    {
        CreatorCoin coin = new CreatorCoin(params, _permit2, _tokenRegistry);

        creatorTokens[address(coin)] = address(coin);

        emit CreatorTokenCreated(address(coin));

        return address(coin);
    }
}
