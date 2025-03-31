// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IPrexPoints} from "../../interfaces/IPrexPoints.sol";
import {CarryToken} from "../CarryToken.sol";
import {Owned} from "solmate/src/auth/Owned.sol";

contract PumConverter is Owned {
    CarryToken public immutable carryToken;
    IPrexPoints public immutable pumPoint;
    IERC20 public immutable dai;

    // point price by DAI
    uint256 public pricePointByDai;

    event PriceUpdated(uint256 newPrice);

    constructor(address _owner, address _prexPoint, address _dai) Owned(_owner) {
        carryToken = new CarryToken(address(this));
        pumPoint = IPrexPoints(_prexPoint);
        dai = IERC20(_dai);
        pricePointByDai = 1e12 / 200;
    }

    function updatePrice(uint256 _price) external onlyOwner {
        pricePointByDai = _price;

        emit PriceUpdated(_price);
    }

    // PumPoint to CarryPoint
    function convertPumPointToCarryPoint(uint256 pumPointAmount, address recipient)
        external
        returns (uint256 carryPointAmount)
    {
        // TODO: Implement convert logic
        // 200 * 1e6 PumPoint = 200 * 1e6 CarryPoint

        carryPointAmount = pumPointAmount;

        pumPoint.consumePoints(msg.sender, pumPointAmount);
        carryToken.mint(recipient, carryPointAmount);
    }

    // CarryPoint to DAI
    function convertCarryPointToDai(uint256 carryPointAmount, address recipient) external returns (uint256 daiAmount) {
        // TODO: Implement convert logic
        // 200 * 1e6 CarryPoint = 1 * 1e18 DAI

        daiAmount = carryPointAmount * pricePointByDai;

        carryToken.burn(msg.sender, carryPointAmount);
        dai.transfer(recipient, daiAmount);
    }
}
