// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {BaseConverter} from "./BaseConverter.sol";

/**
 * @notice FlowRateAdjustment is a base contract for FlowRateAdjustment.
 */
abstract contract FlowRateAdjustment is BaseConverter {
    uint256 public flowRate;

    uint256 public lastFlowRateUpdate;
    uint256 public currentCumulativeAmount;

    event FlowRateUpdated(uint256 newFlowRate);

    error ExceedFlowRate(uint256 amount, uint256 flowRate);

    function __FlowRateAdjustment_init(address _owner) internal onlyInitializing {
        __BaseConverter_init(_owner);

        flowRate = 500000 * 1e6;
    }

    function setFlowRate(uint256 _flowRate) external onlyOwner {
        flowRate = _flowRate;

        emit FlowRateUpdated(_flowRate);
    }

    function checkFlowRate(uint256 _amount) internal {
        uint256 currentHour = block.timestamp / 3600;

        if (lastFlowRateUpdate < currentHour) {
            lastFlowRateUpdate = currentHour;
            currentCumulativeAmount = 0;
        }

        if (currentCumulativeAmount + _amount > flowRate) {
            revert ExceedFlowRate(_amount + currentCumulativeAmount, flowRate);
        }

        currentCumulativeAmount += _amount;
    }
}
