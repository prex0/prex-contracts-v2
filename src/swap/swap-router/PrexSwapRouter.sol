// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {LoyaltyConverter} from "../converter/LoyaltyConverter.sol";
import {PumConverter} from "../converter/PumConverter.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {IPermit2} from "../../../lib/permit2/src/interfaces/IPermit2.sol";
import {ISwapRouter} from "../../interfaces/ISwapRouter.sol";

/**
 * @notice swap router for UniswapV4, V3 and Converter
 */
contract PrexSwapRouter is ISwapRouter {
    using SafeTransferLib for ERC20;

    address public universalRouter;
    LoyaltyConverter public loyaltyConverter;
    PumConverter public pumConverter;
    IPermit2 public permit2;

    constructor(address _universalRouter, address _loyaltyConverter, address _pumConverter, address _permit2) {
        universalRouter = _universalRouter;
        loyaltyConverter = LoyaltyConverter(_loyaltyConverter);
        pumConverter = PumConverter(_pumConverter);
        permit2 = IPermit2(_permit2);

        // approve prex point to pum converter
        ERC20(address(pumConverter.pumPoint())).approve(address(pumConverter), type(uint256).max);

        // approve dai to loyalty converter
        ERC20(address(loyaltyConverter.dai())).approve(address(loyaltyConverter), type(uint256).max);
    }

    /**
     * @notice スワップを実行する
     * @param callbackData スワップのコールバックデータ
     */
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
            uint256 pumPointAmount = ERC20(address(pumConverter.pumPoint())).balanceOf(address(this));

            pumConverter.convertPumPointToCarryPoint(pumPointAmount, address(this));
        } else if (convertParams.convertType == ConvertType.LOYALTY_TO_DAI) {
            uint256 loyaltyCoinAmount = ERC20(convertParams.loyaltyCoin).balanceOf(address(this));

            loyaltyConverter.convertLoyaltyCoinToDai(convertParams.loyaltyCoin, loyaltyCoinAmount, address(this));
        }

        (bool success, bytes memory returnData) = universalRouter.call(data);
        if (!success) {
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }

        if (convertParams.convertType == ConvertType.CARRY_TO_DAI) {
            uint256 carryPointAmount = ERC20(pumConverter.carryToken()).balanceOf(address(this));

            pumConverter.convertCarryPointToDai(carryPointAmount, address(this));
        } else if (convertParams.convertType == ConvertType.DAI_TO_LOYALTY) {
            uint256 daiAmount = loyaltyConverter.dai().balanceOf(address(this));

            loyaltyConverter.convertDaiToLoyaltyCoin(convertParams.loyaltyCoin, daiAmount, address(this));
        }
    }

    /// @notice Necessary for this contract to receive ETH
    receive() external payable {}
}
