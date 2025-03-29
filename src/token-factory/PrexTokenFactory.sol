// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./tokens/MintableCreatorCoin.sol";
import "./tokens/CreatorCoin.sol";
import "./tokens/LoyaltyCoin.sol";
import "./TokenParams.sol";

/**
 * @notice Prex token factory
 */
contract PrexTokenFactory {
    event MintableCreatorCoinCreated(address indexed token);

    mapping(address => address) public mintableCreatorTokens;

    /**
     * @notice Create a mintable creator token
     * 10億枚までmint可能なトークンを発行する
     * @param params トークンのパラメータ
     * @param _permit2 The permit2 address
     * @param _tokenRegistry The token registry address
     * @return The address of the created token
     */
    function createMintableCreatorToken(CreateTokenParameters memory params, address _permit2, address _tokenRegistry)
        public
        returns (address)
    {
        MintableCreatorCoin token = new MintableCreatorCoin(params, _permit2, _tokenRegistry);

        mintableCreatorTokens[address(token)] = address(token);

        emit MintableCreatorCoinCreated(address(token));

        return address(token);
    }
}
