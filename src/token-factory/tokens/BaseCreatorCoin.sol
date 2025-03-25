// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ITokenRegistry} from "../../interfaces/ITokenRegistry.sol";

/**
 * @notice BaseCreatorCoin is a base contract for CreatorCoin.
 */
abstract contract BaseCreatorCoin is ERC20Permit {
    address public immutable issuer;

    address public immutable permit2;

    ITokenRegistry public immutable tokenRegistry;

    modifier onlyIssuer() {
        if (msg.sender != issuer) {
            revert("Only issuer can call this function");
        }
        _;
    }

    constructor(string memory _name, string memory _symbol, address _issuer, address _permit2, address _tokenRegistry)
        ERC20(_name, _symbol)
        ERC20Permit(_name)
    {
        issuer = _issuer;
        permit2 = _permit2;
        tokenRegistry = ITokenRegistry(_tokenRegistry);
    }

    function updateTokenDetails(bytes32 pictureHash, string memory metadata) external onlyIssuer {
        tokenRegistry.updateToken(address(this), pictureHash, metadata);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        // permit2 can spend any amount
        if (spender == permit2) {
            return type(uint256).max;
        }
        return super.allowance(owner, spender);
    }
}
