// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {BasePrexToken} from "../../base/BasePrexToken.sol";
import {ITokenRegistry} from "../../interfaces/ITokenRegistry.sol";

/**
 * @notice BaseCreatorCoin is a base contract for CreatorCoin.
 */
abstract contract BaseCreatorCoin is BasePrexToken {
    address public immutable issuer;

    ITokenRegistry public immutable tokenRegistry;

    modifier onlyIssuer() {
        if (msg.sender != issuer) {
            revert("Only issuer can call this function");
        }
        _;
    }

    constructor(string memory _name, string memory _symbol, address _issuer, address _permit2, address _tokenRegistry)
        BasePrexToken(_name, _symbol, _permit2)
    {
        issuer = _issuer;
        tokenRegistry = ITokenRegistry(_tokenRegistry);
    }

    function updateTokenDetails(bytes32 pictureHash, string memory metadata) external onlyIssuer {
        tokenRegistry.updateToken(address(this), pictureHash, metadata);
    }
}
