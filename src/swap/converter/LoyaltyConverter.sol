// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Owned} from "solmate/src/auth/Owned.sol";
import {ILoyaltyCoin} from "../../interfaces/ILoyaltyCoin.sol";

contract LoyaltyConverter is Owned {
    IERC20 public immutable dai;

    // jpy price by dai
    uint256 public priceJpyByDai;

    // fee rate scaled by 1e6
    uint256 public feeRate;

    error InvalidLoyaltyCoin();

    event PriceUpdated(uint256 newPrice);
    event FeeRateUpdated(uint256 newFeeRate);

    constructor(address _owner, address _dai) Owned(_owner) {
        dai = IERC20(_dai);
        priceJpyByDai = 1e18;
    }

    function updatePrice(uint256 _price) external onlyOwner {
        priceJpyByDai = _price;

        emit PriceUpdated(_price);
    }

    function updateFeeRate(uint256 _feeRate) external onlyOwner {
        feeRate = _feeRate;

        emit FeeRateUpdated(_feeRate);
    }

    // LoyaltyCoin to DAI
    function convertLoyaltyCoinToDai(address loyaltyCoin, uint256 loyaltyCoinAmount, address recipient)
        external
        returns (uint256 daiAmount)
    {
        // TODO: Implement convert logic
        // 1 LoyaltyCoin = 1 DAI

        if (loyaltyCoin != _getLoyaltyCoin(loyaltyCoin)) {
            revert InvalidLoyaltyCoin();
        }

        daiAmount = loyaltyCoinAmount * priceJpyByDai / 1e6;
        uint256 fee = daiAmount * feeRate / 1e6;
        daiAmount -= fee;

        ILoyaltyCoin(loyaltyCoin).burn(msg.sender, loyaltyCoinAmount);
        dai.transfer(recipient, daiAmount);
    }

    // DAI to LoyaltyCoin
    function convertDaiToLoyaltyCoin(address loyaltyCoin, uint256 daiAmount, address recipient)
        external
        returns (uint256 loyaltyCoinAmount)
    {
        // TODO: Implement convert logic
        // 1 DAI = 1 LoyaltyCoin

        if (loyaltyCoin != _getLoyaltyCoin(loyaltyCoin)) {
            revert InvalidLoyaltyCoin();
        }

        loyaltyCoinAmount = daiAmount * 1e6 / priceJpyByDai;

        dai.transferFrom(msg.sender, address(this), daiAmount);
        ILoyaltyCoin(loyaltyCoin).mint(recipient, loyaltyCoinAmount);
    }

    function _getLoyaltyCoin(address) internal view virtual returns (address) {
        return address(0);
    }
}
