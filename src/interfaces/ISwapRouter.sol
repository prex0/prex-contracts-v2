// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface ISwapRouter {
    enum ConvertType {
        NOOP,
        PUM_TO_CARRY,
        CARRY_TO_DAI,
        LOYALTY_TO_DAI,
        DAI_TO_LOYALTY
    }

    struct ConvertParams {
        ConvertType convertType;
        address loyaltyCoin;
    }
}
