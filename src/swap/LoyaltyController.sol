// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {CreateTokenParameters} from "../token-factory/TokenParams.sol";
import {LoyaltyCoin} from "../token-factory/tokens/LoyaltyCoin.sol";
import {LoyaltyConverter} from "./converter/LoyaltyConverter.sol";

contract LoyaltyController is LoyaltyConverter {
    // loyalty token address -> loyalty coin address
    mapping(address => address) public loyaltyTokens;

    event LoyaltyCoinCreated(address indexed loyaltyToken);

    constructor(address _owner, address _dai) LoyaltyConverter(_owner, _dai) {}

    // issue loyalty coin
    function issueLoyaltyCoin() external {
        // TODO: Implement swap logic
    }

    // mint loyalty coin
    function mintLoyaltyCoin() external {
        // TODO: Implement swap logic
    }

    /**
     * @notice Create a loyalty token
     * @param params トークンのパラメータ
     * @param _permit2 The permit2 address
     * @param _tokenRegistry The token registry address
     * @return The address of the created token
     */
    function createLoyaltyToken(CreateTokenParameters memory params, address _permit2, address _tokenRegistry)
        internal
        returns (address)
    {
        LoyaltyCoin token = new LoyaltyCoin(params, address(this), _permit2, _tokenRegistry);

        loyaltyTokens[address(token)] = address(token);

        emit LoyaltyCoinCreated(address(token));

        return address(token);
    }

    function _getLoyaltyCoin(address loyaltyToken) internal override returns (address) {
        return loyaltyTokens[loyaltyToken];
    }
}
