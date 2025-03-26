// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {WhitelistHandler} from "./WhitelistHandler.sol";

/**
 * @notice クレジット価格を管理するコントラクト
 */
contract CreditPrice is WhitelistHandler {
    // default credit price is 5_000_000;
    uint256 public creditPrice = 5 * 1e6;

    constructor(address _owner) WhitelistHandler(_owner) {}

    /**
     * @notice クレジット価格を設定する
     * @dev 管理者だけが設定できる
     * @param _creditPrice クレジット価格
     */
    function setCreditPrice(uint256 _creditPrice) external onlyOwner {
        creditPrice = _creditPrice;
    }
}
