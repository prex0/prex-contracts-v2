// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {FlowRateAdjustment} from "../../src/base/FlowRateAdjustment.sol";

contract WrapperFlowRateAdjustment is FlowRateAdjustment {
    function __WrapperFlowRateAdjustment_init(address _owner) public initializer {
        __FlowRateAdjustment_init(_owner);
    }

    function throwAmount(uint256 amount) external {
        checkFlowRate(amount);
    }
}

contract FlowRateAdjustmentTest is Test {
    WrapperFlowRateAdjustment public wrapper;

    address public owner = vm.addr(5);

    function setUp() public virtual {
        wrapper = new WrapperFlowRateAdjustment();
        wrapper.__WrapperFlowRateAdjustment_init(owner);

        vm.startPrank(owner);
        wrapper.setFlowRate(1000);
        vm.stopPrank();
    }

    function test_throwAmount() public {
        wrapper.throwAmount(100);
    }

    function test_throwAmount_revert() public {
        vm.expectRevert(abi.encodeWithSelector(FlowRateAdjustment.ExceedFlowRate.selector, 1001, 1000));
        wrapper.throwAmount(1001);
    }

    function test_throwAmount_revert_cumulative() public {
        wrapper.throwAmount(100);

        vm.expectRevert(abi.encodeWithSelector(FlowRateAdjustment.ExceedFlowRate.selector, 1001, 1000));
        wrapper.throwAmount(901);

        vm.warp(block.timestamp + 3600);
        wrapper.throwAmount(100);
    }
}
