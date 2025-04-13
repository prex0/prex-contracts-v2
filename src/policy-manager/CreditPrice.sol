// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {WhitelistHandler} from "./WhitelistHandler.sol";

/**
 * @notice クレジット価格を管理するコントラクト
 */
contract CreditPrice is WhitelistHandler {
    // default credit price is 1_000_000;
    uint256 public creditPrice = 1 * 1e6;

    event CreditPriceUpdated(uint256 creditPrice);

    function __CreditPrice_init(address _owner) internal onlyInitializing {
        __WhitelistHandler_init(_owner);
    }

    /**
     * @notice クレジット価格を設定する
     * @dev 管理者だけが設定できる
     * @param _creditPrice クレジット価格
     */
    function setCreditPrice(uint256 _creditPrice) external onlyOwner {
        creditPrice = _creditPrice;

        emit CreditPriceUpdated(_creditPrice);
    }
}
