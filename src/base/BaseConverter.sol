// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Owned} from "solmate/src/auth/Owned.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @notice BaseConverter is a base contract for Converter.
 */
abstract contract BaseConverter is Owned {
    IERC20 public dai;

    constructor(address _owner) Owned(_owner) {}

    /**
     * @notice Set the DAI address
     * @dev This function can only be called by the owner
     * @param _dai The address of the DAI token
     */
    function setDai(address _dai) external onlyOwner {
        dai = IERC20(_dai);
    }

    /**
     * @notice Deposit DAI to the contract
     * @param daiAmount The amount of DAI to deposit
     */
    function depositDai(uint256 daiAmount) external onlyOwner {
        dai.transferFrom(msg.sender, address(this), daiAmount);
    }

    /**
     * @notice Withdraw DAI from the contract
     * @param daiAmount The amount of DAI to withdraw
     * @param recipient The address to receive the DAI
     */
    function withdrawDai(uint256 daiAmount, address recipient) external onlyOwner {
        dai.transfer(recipient, daiAmount);
    }
}
