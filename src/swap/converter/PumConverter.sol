// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IPrexPoints} from "../../interfaces/IPrexPoints.sol";
import {CarryToken} from "../CarryToken.sol";
import {PriceLibrary} from "../../libraries/PriceLibrary.sol";
import {BaseConverter} from "../../base/BaseConverter.sol";

contract PumConverter is BaseConverter {
    using PriceLibrary for uint256;

    CarryToken public immutable carryToken;
    IPrexPoints public immutable pumPoint;

    // point price by DAI
    uint256 public pricePointByDai = 1e30 / 200;

    event PriceUpdated(uint256 newPrice);

    constructor(address _owner, address _prexPoint, address _dai) BaseConverter(_owner, _dai) {
        carryToken = new CarryToken(address(this));
        pumPoint = IPrexPoints(_prexPoint);
    }

    /**
     * @notice Update the price of 1e12 PumPoint in 1e18
     * @param _price The new price of 1e12 PumPoint in 1e18
     */
    function updatePrice(uint256 _price) external onlyOwner {
        pricePointByDai = _price;

        emit PriceUpdated(_price);
    }

    // PumPoint to CarryPoint
    function convertPumPointToCarryPoint(uint256 pumPointAmount, address recipient)
        external
        returns (uint256 carryPointAmount)
    {
        // 200 * 1e6 PumPoint = 200 * 1e6 CarryPoint

        carryPointAmount = pumPointAmount;

        pumPoint.consumePoints(msg.sender, pumPointAmount);
        carryToken.mint(recipient, carryPointAmount);
    }

    // CarryPoint to DAI
    function convertCarryPointToDai(uint256 carryPointAmount, address recipient) external returns (uint256 daiAmount) {
        // 200 * 1e6 CarryPoint = 1 * 1e18 DAI

        daiAmount = carryPointAmount.applyPrice(pricePointByDai);

        carryToken.burn(msg.sender, carryPointAmount);
        dai.transfer(recipient, daiAmount);
    }
}
