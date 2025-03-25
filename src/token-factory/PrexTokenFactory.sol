// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./tokens/MintableCreatorCoin.sol";
import "./tokens/CreatorCoin.sol";

/**
 * @notice Prex token factory
 */
contract PrexTokenFactory {
    event CreatorCoinCreated(address indexed token);
    event MintableCreatorCoinCreated(address indexed token);

    /**
     * @notice Create a creator token
     * pumpumの推しの証を作成する
     * @param _name The name of the token
     * @param _symbol The symbol of the token
     * @param _initialSupply The initial supply of the token
     * @param _recipient The recipient of the initial supply
     * @param _issuer The issuer of the token
     * @param _permit2 The permit2 address
     * @param _tokenRegistry The token registry address
     * @return The address of the created token
     */
    function createCreatorToken(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _recipient,
        address _issuer,
        address _permit2,
        address _tokenRegistry
    ) public returns (address) {
        CreatorCoin coin =
            new CreatorCoin(_name, _symbol, _initialSupply, _recipient, _issuer, _permit2, _tokenRegistry);

        emit CreatorCoinCreated(address(coin));

        return address(coin);
    }

    /**
     * @notice Create a mintable creator token
     * 10億枚までmint可能なトークンを発行する
     * @param _name The name of the token
     * @param _symbol The symbol of the token
     * @param _initialSupply The initial supply of the token
     * @param _recipient The recipient of the initial supply
     * @param _issuer The issuer of the token
     * @param _permit2 The permit2 address
     * @param _tokenRegistry The token registry address
     * @return The address of the created token
     */
    function createMintableCreatorToken(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _recipient,
        address _issuer,
        address _permit2,
        address _tokenRegistry
    ) public returns (address) {
        MintableCreatorCoin token =
            new MintableCreatorCoin(_name, _symbol, _initialSupply, _recipient, _issuer, _permit2, _tokenRegistry);

        emit MintableCreatorCoinCreated(address(token));

        return address(token);
    }
}
