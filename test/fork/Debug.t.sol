// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {V4Quoter} from "../../lib/v4-periphery/src/lens/V4Quoter.sol";
import {IV4Quoter} from "../../lib/v4-periphery/src/interfaces/IV4Quoter.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";

contract Debug is Test {
    // the identifiers of the forks
    uint256 optimismFork;

    //Access variables from .env file via vm.envString("varname")
    //Replace ALCHEMY_KEY by your alchemy key or Etherscan key, change RPC url if need
    //inside your .env file e.g:
    //MAINNET_RPC_URL = 'https://eth-mainnet.g.alchemy.com/v2/ALCHEMY_KEY'
    //string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    string OPTIMISM_RPC_URL = "https://arb-sepolia.g.alchemy.com/v2/qhUlv79pBClUQqtxpA5lITdEXhxTuKhB";

    // create two _different_ forks during setup
    function setUp() public virtual {
        optimismFork = vm.createFork(OPTIMISM_RPC_URL);
        vm.selectFork(optimismFork);
        vm.rollFork(139468650);
        // vm.chainId(10);
    }

    function testQuoter() public {
        V4Quoter quoter = V4Quoter(0x7dE51022d70A725b508085468052E25e22b5c4c9);

        (uint256 amountOut, uint256 gasEstimate) = quoter.quoteExactInputSingle(
            IV4Quoter.QuoteExactSingleParams({
                poolKey: _getPoolKey(
                    address(0xBDF9D0080c682Aa2b7e24FCE0330999c14Cec138), address(0xE8608327EBECe78579c8522757E7E2ae1Ba35E2E)
                ),
                zeroForOne: true,
                exactAmount: 1000000000,
                hookData: bytes("")
            })
        );

        assertEq(amountOut, 582632617164108882089834);
        assertEq(gasEstimate, 288678);
    }

    function _getPoolKey(address tokenA, address tokenB) internal pure returns (PoolKey memory) {
        Currency currency0 = Currency.wrap(tokenA);
        Currency currency1 = Currency.wrap(tokenB);
        if (tokenA > tokenB) {
            (currency0, currency1) = (currency1, currency0);
        }
        return PoolKey({
            currency0: currency0,
            currency1: currency1,
            // 6.0%
            fee: 60_000,
            tickSpacing: 60,
            hooks: IHooks(address(0xC99435d949bc8892D56691cA63D1e853324B00c0))
        });
    }
}
