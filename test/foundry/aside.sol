//     function testWithdrawLiquidity() public {
//     console.log("testWithdrawLiquidity - Starting test");
//     (address token,) = createTokensAndAddLiquidity();

//     vm.warp(block.timestamp + 4 days); // Fast forward time
//     console.log("testWithdrawLiquidity - Time fast-forwarded by 4 days");

//     uint256 initialWithdrawableLiquidity = KannonV1.tokenInfo(token).withdrawableLiquidity;
//     console.log("testWithdrawLiquidity - Initial withdrawable liquidity:", initialWithdrawableLiquidity);

//     uint256 amountToWithdraw = initialWithdrawableLiquidity / 2;
//     console.log("testWithdrawLiquidity - Amount to withdraw:", amountToWithdraw);

//     vm.prank(deployer);
//     KannonV1.withdrawLiquidity(token, amountToWithdraw);
//     console.log("testWithdrawLiquidity - Liquidity withdrawn");

//     uint256 finalWithdrawableLiquidity = KannonV1.tokenInfo(token).withdrawableLiquidity;
//     console.log("testWithdrawLiquidity - Final withdrawable liquidity:", finalWithdrawableLiquidity);

//     assertEq(
//         finalWithdrawableLiquidity,
//         initialWithdrawableLiquidity - amountToWithdraw,
//         "Withdrawable liquidity not updated correctly"
//     );
//     console.log("testWithdrawLiquidity - Test completed");
// }

// function testCollectFees() public {
//     console.log("testCollectFees - Starting test");
//     (address token,) = createTokensAndAddLiquidity();

//     performSwaps();
//     console.log("testCollectFees - Swaps performed to generate fees");

//     vm.prank(deployer);
//     (uint256 amount0, uint256 amount1) = KannonV1.collectFees(token);

//     console.log("testCollectFees - Collected fees:");
//     console.log("  Amount0:", amount0);
//     console.log("  Amount1:", amount1);

//     assertTrue(amount0 > 0 || amount1 > 0, "No fees collected");
//     console.log("testCollectFees - Test completed");
// }

// function testGetTokenPrice() public {
//     console.log("testGetTokenPrice - Starting test");
//     (address token,) = createTokensAndAddLiquidity();

//     uint256 initialPrice = KannonV1.getTokenPrice(token);
//     console.log("testGetTokenPrice - Initial token price:", initialPrice);
//     assertTrue(initialPrice > 0, "Initial token price should be greater than zero");

//     performSwaps();
//     console.log("testGetTokenPrice - Swaps performed");

//     uint256 finalPrice = KannonV1.getTokenPrice(token);
//     console.log("testGetTokenPrice - Final token price:", finalPrice);
//     assertTrue(finalPrice != initialPrice, "Token price did not change after swaps");
//     console.log("testGetTokenPrice - Test completed");
// }
