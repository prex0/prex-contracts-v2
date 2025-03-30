// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {LoyaltyConverter} from "../converter/LoyaltyConverter.sol";
import {PumConverter} from "../converter/PumConverter.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {IPermit2} from "../../../lib/permit2/src/interfaces/IPermit2.sol";

/**
 * swap router for UniswapV4, V3 and Converter
 */
contract PrexSwapRouter {
    using SafeTransferLib for ERC20;

    address public universalRouter;
    LoyaltyConverter public loyaltyConverter;
    PumConverter public pumConverter;
    IPermit2 public permit2;

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
        uint256 amount;
    }

    constructor(address _universalRouter, address _loyaltyConverter, address _pumConverter, address _permit2) {
        universalRouter = _universalRouter;
        loyaltyConverter = LoyaltyConverter(_loyaltyConverter);
        pumConverter = PumConverter(_pumConverter);
        permit2 = IPermit2(_permit2);
    }

    function _executeSwap(bytes memory callbackData) internal {
        (address[] memory tokensToApproveForUniversalRouter, ConvertParams memory convertParams, bytes memory data) =
            abi.decode(callbackData, (address[], ConvertParams, bytes));

        // TODO: approve
        unchecked {
            for (uint256 i = 0; i < tokensToApproveForUniversalRouter.length; i++) {
                ERC20(tokensToApproveForUniversalRouter[i]).safeApprove(address(permit2), type(uint256).max);

                permit2.approve(
                    tokensToApproveForUniversalRouter[i], address(universalRouter), type(uint160).max, type(uint48).max
                );
            }
        }

        // TODO: pre convert
        if (convertParams.convertType == ConvertType.PUM_TO_CARRY) {
            pumConverter.convertPumPointToCarryPoint(convertParams.amount, address(this));
        } else if (convertParams.convertType == ConvertType.LOYALTY_TO_DAI) {
            loyaltyConverter.convertLoyaltyCoinToDai(convertParams.loyaltyCoin, convertParams.amount, address(this));
        }

        (bool success, bytes memory returnData) = universalRouter.call(data);
        if (!success) {
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }

        if (convertParams.convertType == ConvertType.CARRY_TO_DAI) {
            pumConverter.convertCarryPointToDai(convertParams.amount, address(this));
        } else if (convertParams.convertType == ConvertType.DAI_TO_LOYALTY) {
            loyaltyConverter.convertDaiToLoyaltyCoin(convertParams.loyaltyCoin, convertParams.amount, address(this));
        }
    }
}
