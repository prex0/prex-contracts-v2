// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IPrexPoints} from "../../interfaces/IPrexPoints.sol";
import {CarryToken} from "../CarryToken.sol";
import {PriceLibrary} from "../../libraries/PriceLibrary.sol";
import {FlowRateAdjustment} from "../../base/FlowRateAdjustment.sol";

contract PumConverter is FlowRateAdjustment {
    using PriceLibrary for uint256;

    CarryToken public carryToken;
    IPrexPoints public pumPoint;

    // point price by DAI
    uint256 public pricePointByDai;

    event PriceUpdated(uint256 newPrice);

    function __PumConverter_init(address _owner, address _prexPoint) internal onlyInitializing {
        __FlowRateAdjustment_init(_owner);

        pumPoint = IPrexPoints(_prexPoint);
        pricePointByDai = 1e30 / 200;
    }

    function setCarryToken(address _carryToken) external onlyOwner {
        carryToken = CarryToken(_carryToken);
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

        checkFlowRate(pumPointAmount);

        carryPointAmount = pumPointAmount;

        IERC20(address(pumPoint)).transferFrom(msg.sender, address(this), pumPointAmount);

        pumPoint.burn(pumPointAmount);

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
