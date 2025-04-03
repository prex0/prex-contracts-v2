// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {CreateTokenParameters} from "../token-factory/TokenParams.sol";
import {LoyaltyCoin} from "../token-factory/tokens/LoyaltyCoin.sol";
import {LoyaltyConverter} from "./converter/LoyaltyConverter.sol";
import {IPrexPoints} from "../interfaces/IPrexPoints.sol";

contract LoyaltyController is LoyaltyConverter {
    // loyalty token address -> loyalty coin address
    mapping(address => address) public loyaltyTokens;

    mapping(string => bool) public symbolUsed;

    error SymbolAlreadyUsed(string symbol);

    address public immutable loyaltyPoint;

    event LoyaltyCoinMinted(
        address indexed loyaltyToken, address indexed recipient, uint256 amount, uint256 loyaltyPointAmount
    );

    constructor(address _owner, address _loyaltyPoint) LoyaltyConverter(_owner) {
        loyaltyPoint = _loyaltyPoint;
    }

    // mint loyalty coin
    function mintLoyaltyCoin(address loyaltyCoinAddress, address recipient, uint256 amount) external {
        uint256 loyaltyPointAmount = amount / 1e12;

        // check hourly flow rate
        checkFlowRate(loyaltyPointAmount);

        require(loyaltyPointAmount * 1e12 == amount, "LoyaltyController: amount is not a multiple of 1e12");

        if (loyaltyTokens[loyaltyCoinAddress] == address(0)) {
            revert InvalidLoyaltyCoin();
        }

        IPrexPoints(loyaltyPoint).consumePoints(msg.sender, loyaltyPointAmount);
        LoyaltyCoin(loyaltyCoinAddress).mint(recipient, amount);

        emit LoyaltyCoinMinted(loyaltyCoinAddress, recipient, amount, loyaltyPointAmount);
    }

    /**
     * @notice Create a loyalty token
     * @param params トークンのパラメータ
     * @param _permit2 The permit2 address
     * @param _tokenRegistry The token registry address
     * @return The address of the created token
     */
    function _createLoyaltyToken(CreateTokenParameters memory params, address _permit2, address _tokenRegistry)
        internal
        returns (address)
    {
        if (symbolUsed[params.symbol]) {
            revert SymbolAlreadyUsed(params.symbol);
        }

        LoyaltyCoin token = new LoyaltyCoin(params, address(this), _permit2, _tokenRegistry);

        symbolUsed[params.symbol] = true;

        loyaltyTokens[address(token)] = address(token);

        return address(token);
    }

    function _getLoyaltyCoin(address loyaltyToken) internal view override returns (address) {
        return loyaltyTokens[loyaltyToken];
    }
}
