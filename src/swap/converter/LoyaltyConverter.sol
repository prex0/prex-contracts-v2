// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ILoyaltyCoin} from "../../interfaces/ILoyaltyCoin.sol";
import {PriceLibrary} from "../../libraries/PriceLibrary.sol";
import {BipsLibrary} from "../../libraries/BipsLibrary.sol";
import {BaseConverter} from "../../base/BaseConverter.sol";

contract LoyaltyConverter is BaseConverter {
    using PriceLibrary for uint256;
    using BipsLibrary for uint256;

    // jpy price by dai (150 jpy = 1 dai)
    uint256 public priceJpyByDai = 6667 * 1e12;

    // fee rate scaled by 1e6
    uint256 public feeRate = 100;

    error InvalidLoyaltyCoin();

    event PriceUpdated(uint256 newPrice);
    event FeeRateUpdated(uint256 newFeeRate);

    constructor(address _owner) BaseConverter(_owner) {}

    /**
     * @notice Update the price of 1 JPY in 1e18
     * @param _price The new price of 1 JPY scaled by 1e18
     */
    function updatePrice(uint256 _price) external onlyOwner {
        priceJpyByDai = _price;

        emit PriceUpdated(_price);
    }

    /**
     * @notice Update the fee rate scaled by 1e6
     * @param _feeRate The new fee rate scaled by 1e6
     */
    function updateFeeRate(uint256 _feeRate) external onlyOwner {
        feeRate = _feeRate;

        emit FeeRateUpdated(_feeRate);
    }

    // LoyaltyCoin to DAI
    function convertLoyaltyCoinToDai(address loyaltyCoin, uint256 loyaltyCoinAmount, address recipient)
        external
        returns (uint256 daiAmount)
    {
        // 1 LoyaltyCoin = 1 DAI

        if (loyaltyCoin != _getLoyaltyCoin(loyaltyCoin)) {
            revert InvalidLoyaltyCoin();
        }

        daiAmount = loyaltyCoinAmount.applyPrice(priceJpyByDai);
        uint256 fee = daiAmount.calculatePortion(feeRate);
        daiAmount -= fee;

        ILoyaltyCoin(loyaltyCoin).burn(msg.sender, loyaltyCoinAmount);
        dai.transfer(recipient, daiAmount);
    }

    // DAI to LoyaltyCoin
    function convertDaiToLoyaltyCoin(address loyaltyCoin, uint256 daiAmount, address recipient)
        external
        returns (uint256 loyaltyCoinAmount)
    {
        // 1 DAI = 1 LoyaltyCoin

        if (loyaltyCoin != _getLoyaltyCoin(loyaltyCoin)) {
            revert InvalidLoyaltyCoin();
        }

        loyaltyCoinAmount = daiAmount.applyPriceInverse(priceJpyByDai);
        uint256 fee = loyaltyCoinAmount.calculatePortion(feeRate);
        loyaltyCoinAmount -= fee;

        dai.transferFrom(msg.sender, address(this), daiAmount);
        ILoyaltyCoin(loyaltyCoin).mint(recipient, loyaltyCoinAmount);
    }

    function _getLoyaltyCoin(address) internal view virtual returns (address) {
        return address(0);
    }
}
