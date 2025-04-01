// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title For calculating a price of an amount
library PriceLibrary {
    uint256 internal constant PRICE_DENOMINATOR = 1e18;

    /// @param amount The total amount to calculate a price of
    /// @param price The price to calculate, in 1e18
    function applyPrice(uint256 amount, uint256 price) internal pure returns (uint256) {
        return (amount * price) / PRICE_DENOMINATOR;
    }

    /// @param amount The total amount to calculate a price of
    /// @param price The price to calculate, in 1e18
    function applyPriceInverse(uint256 amount, uint256 price) internal pure returns (uint256) {
        return (amount * PRICE_DENOMINATOR) / price;
    }
}
