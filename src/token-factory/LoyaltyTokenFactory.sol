// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./tokens/LoyaltyCoin.sol";
import "./TokenParams.sol";

/**
 * @notice Loyalty token factory
 */
contract LoyaltyTokenFactory {
    /**
     * @notice Create a loyalty token
     * @param params トークンのパラメータ
     * @param _permit2 The permit2 address
     * @param _tokenRegistry The token registry address
     * @return The address of the created token
     */
    function createLoyaltyToken(
        CreateTokenParameters memory params,
        address _issuer,
        address _permit2,
        address _tokenRegistry
    ) external returns (address) {
        LoyaltyCoin token = new LoyaltyCoin(params, _issuer, _permit2, _tokenRegistry);

        return address(token);
    }
}
