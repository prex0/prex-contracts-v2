// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {OrderHeader} from "./IOrderHandler.sol";

interface IPolicyValidator {
    function validatePolicy(
        OrderHeader memory header,
        bytes calldata appSig
    ) external view returns (address);
}
