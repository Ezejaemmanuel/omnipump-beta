// // SPDX-License-Identifier: MIT

// import "forge-std/Test.sol";
// import {BondingCurveLib} from "../../src/kannon_v1_bonding_curve.sol";

// pragma solidity ^0.8.19;

// contract BondingCurveTest is Test {
//     using BondingCurveLib for *;

//     uint256 constant INITIAL_SUPPLY = 1_000_000 * 1e18; // 1 million tokens
//     uint256 constant INITIAL_ETH = 1 ether; // 1 ETH
//     uint256 constant K = INITIAL_SUPPLY * INITIAL_ETH; // K = initial supply * initial ETH (1 ETH)
//     uint256 constant PRECISION = 1e8;

//     struct CurveState {
//         uint256 totalEthCollected;
//         uint256 remainingTokens;
//     }

//     CurveState public state;

//     function setUp() public {
//         state.totalEthCollected = 1 ether; // Start with 1 ETH collected
//         state.remainingTokens = INITIAL_SUPPLY;
//         console.log("Initial setup - Total ETH collected:", state.totalEthCollected);
//         console.log("Initial setup - Remaining tokens:", state.remainingTokens);
//     }

//     function testInitialTokenPurchase() public {
//         console.log("\n--- Starting testInitialTokenPurchase ---");

//         // Test case 1: Small initial purchase
//         uint256 ethAmount1 = 0.1 ether;
//         console.log("\nTest Case 1 - Small purchase of", ethAmount1);
//         uint256 expectedTokens1 = calculateExpectedTokens(state.totalEthCollected, state.remainingTokens, ethAmount1);
//         uint256 actualTokens1 =
//             BondingCurveLib.calculateTokenAmount(state.totalEthCollected, state.remainingTokens, ethAmount1, K);

//         console.log("Expected tokens:", expectedTokens1);
//         console.log("Actual tokens:", actualTokens1);
//         assertApproxEqRel(actualTokens1, expectedTokens1, 1e15, "Small initial purchase calculation mismatch");

//         // Update state
//         state.totalEthCollected += ethAmount1;
//         state.remainingTokens -= actualTokens1;
//         console.log("Updated total ETH collected:", state.totalEthCollected);
//         console.log("Updated remaining tokens:", state.remainingTokens);

//         // Test case 2: Medium initial purchase
//         uint256 ethAmount2 = 1 ether;
//         console.log("\nTest Case 2 - Medium purchase of", ethAmount2);
//         uint256 expectedTokens2 = calculateExpectedTokens(state.totalEthCollected, state.remainingTokens, ethAmount2);
//         uint256 actualTokens2 =
//             BondingCurveLib.calculateTokenAmount(state.totalEthCollected, state.remainingTokens, ethAmount2, K);

//         console.log("Expected tokens:", expectedTokens2);
//         console.log("Actual tokens:", actualTokens2);
//         assertApproxEqRel(actualTokens2, expectedTokens2, 1e15, "Medium initial purchase calculation mismatch");

//         // Update state
//         state.totalEthCollected += ethAmount2;
//         state.remainingTokens -= actualTokens2;
//         console.log("Updated total ETH collected:", state.totalEthCollected);
//         console.log("Updated remaining tokens:", state.remainingTokens);

//         // Test case 3: Large initial purchase
//         uint256 ethAmount3 = 10 ether;
//         console.log("\nTest Case 3 - Large purchase of", ethAmount3);
//         uint256 expectedTokens3 = calculateExpectedTokens(state.totalEthCollected, state.remainingTokens, ethAmount3);
//         uint256 actualTokens3 =
//             BondingCurveLib.calculateTokenAmount(state.totalEthCollected, state.remainingTokens, ethAmount3, K);

//         console.log("Expected tokens:", expectedTokens3);
//         console.log("Actual tokens:", actualTokens3);
//         assertApproxEqRel(actualTokens3, expectedTokens3, 1e15, "Large initial purchase calculation mismatch");

//         // Verify final state
//         console.log("\nFinal State Verification:");
//         console.log("Final ETH collected:", state.totalEthCollected + ethAmount3);
//         console.log("Final remaining tokens:", state.remainingTokens - actualTokens3);
//         assertEq(state.totalEthCollected + ethAmount3, 12.1 ether, "Final ETH collected mismatch");
//         assertEq(
//             state.remainingTokens - actualTokens3,
//             INITIAL_SUPPLY - (actualTokens1 + actualTokens2 + actualTokens3),
//             "Final remaining tokens mismatch"
//         );

//         console.log("--- Ending testInitialTokenPurchase ---\n");
//     }

//     function testMultipleTokenPurchases() public {
//         console.log("\n--- Starting testMultipleTokenPurchases ---");

//         uint256[] memory ethAmounts = new uint256[](5);
//         ethAmounts[0] = 0.5 ether;
//         ethAmounts[1] = 1 ether;
//         ethAmounts[2] = 2 ether;
//         ethAmounts[3] = 5 ether;
//         ethAmounts[4] = 10 ether;

//         uint256 totalTokensPurchased = 0;

//         for (uint256 i = 0; i < ethAmounts.length; i++) {
//             console.log("\nPurchase", i + 1, "- ETH amount:", ethAmounts[i]);
//             uint256 expectedTokens =
//                 calculateExpectedTokens(state.totalEthCollected, state.remainingTokens, ethAmounts[i]);
//             uint256 actualTokens =
//                 BondingCurveLib.calculateTokenAmount(state.totalEthCollected, state.remainingTokens, ethAmounts[i], K);

//             console.log("Expected tokens:", expectedTokens);
//             console.log("Actual tokens:", actualTokens);
//             assertApproxEqRel(
//                 actualTokens,
//                 expectedTokens,
//                 1e15,
//                 string(abi.encodePacked("Purchase ", uint256(i + 1), " calculation mismatch"))
//             );

//             // Update state
//             state.totalEthCollected += ethAmounts[i];
//             state.remainingTokens -= actualTokens;
//             totalTokensPurchased += actualTokens;

//             console.log("Updated total ETH collected:", state.totalEthCollected);
//             console.log("Updated remaining tokens:", state.remainingTokens);
//             console.log("Total tokens purchased so far:", totalTokensPurchased);

//             // Verify intermediate state
//             assertEq(
//                 state.remainingTokens,
//                 INITIAL_SUPPLY - totalTokensPurchased,
//                 string(abi.encodePacked("Remaining tokens mismatch after purchase ", uint256(i + 1)))
//             );
//         }

//         // Verify final state
//         console.log("\nFinal State Verification:");
//         console.log("Final ETH collected:", state.totalEthCollected);
//         console.log("Final remaining tokens:", state.remainingTokens);
//         assertEq(state.totalEthCollected, 19.5 ether, "Final ETH collected mismatch");
//         assertEq(state.remainingTokens, INITIAL_SUPPLY - totalTokensPurchased, "Final remaining tokens mismatch");

//         // Test a purchase after multiple transactions
//         uint256 finalPurchaseEth = 1 ether;
//         console.log("\nFinal purchase after multiple transactions - ETH amount:", finalPurchaseEth);
//         uint256 expectedFinalTokens =
//             calculateExpectedTokens(state.totalEthCollected, state.remainingTokens, finalPurchaseEth);
//         uint256 actualFinalTokens =
//             BondingCurveLib.calculateTokenAmount(state.totalEthCollected, state.remainingTokens, finalPurchaseEth, K);

//         console.log("Expected final tokens:", expectedFinalTokens);
//         console.log("Actual final tokens:", actualFinalTokens);
//         assertApproxEqRel(
//             actualFinalTokens, expectedFinalTokens, 1e15, "Final purchase after multiple transactions mismatch"
//         );

//         console.log("--- Ending testMultipleTokenPurchases ---\n");
//     }

//     function testLargeTokenPurchase() public {
//         console.log("\n--- Starting testLargeTokenPurchase ---");

//         uint256 largeEthAmount = 100 ether;
//         console.log("Large purchase amount:", largeEthAmount);

//         uint256 expectedTokens = calculateExpectedTokens(state.totalEthCollected, state.remainingTokens, largeEthAmount);
//         uint256 actualTokens =
//             BondingCurveLib.calculateTokenAmount(state.totalEthCollected, state.remainingTokens, largeEthAmount, K);

//         console.log("Expected tokens for large purchase:", expectedTokens);
//         console.log("Actual tokens for large purchase:", actualTokens);
//         assertApproxEqRel(actualTokens, expectedTokens, 1e15, "Large purchase calculation mismatch");

//         // Update state
//         state.totalEthCollected += largeEthAmount;
//         state.remainingTokens -= actualTokens;

//         console.log("Updated total ETH collected:", state.totalEthCollected);
//         console.log("Updated remaining tokens:", state.remainingTokens);

//         // Verify the impact on token price
//         uint256 smallPurchaseAmount = 0.1 ether;
//         uint256 tokensBeforeLargePurchase = calculateExpectedTokens(1 ether, INITIAL_SUPPLY, smallPurchaseAmount);
//         uint256 tokensAfterLargePurchase =
//             calculateExpectedTokens(state.totalEthCollected, state.remainingTokens, smallPurchaseAmount);

//         console.log("Tokens for 0.1 ETH before large purchase:", tokensBeforeLargePurchase);
//         console.log("Tokens for 0.1 ETH after large purchase:", tokensAfterLargePurchase);
//         assertTrue(
//             tokensAfterLargePurchase < tokensBeforeLargePurchase, "Token price should increase after large purchase"
//         );

//         console.log("--- Ending testLargeTokenPurchase ---\n");
//     }

//     function testSmallTokenPurchase() public {
//         console.log("\n--- Starting testSmallTokenPurchase ---");

//         uint256 smallEthAmount = 0.001 ether;
//         console.log("Small purchase amount:", smallEthAmount);

//         uint256 expectedTokens = calculateExpectedTokens(state.totalEthCollected, state.remainingTokens, smallEthAmount);
//         uint256 actualTokens =
//             BondingCurveLib.calculateTokenAmount(state.totalEthCollected, state.remainingTokens, smallEthAmount, K);

//         console.log("Expected tokens for small purchase:", expectedTokens);
//         console.log("Actual tokens for small purchase:", actualTokens);
//         assertApproxEqRel(actualTokens, expectedTokens, 1e15, "Small purchase calculation mismatch");

//         // Update state
//         state.totalEthCollected += smallEthAmount;
//         state.remainingTokens -= actualTokens;

//         console.log("Updated total ETH collected:", state.totalEthCollected);
//         console.log("Updated remaining tokens:", state.remainingTokens);

//         // Verify that small purchases are possible and don't revert
//         uint256 verySmallEthAmount = 1 wei;
//         uint256 verySmallTokens =
//             BondingCurveLib.calculateTokenAmount(state.totalEthCollected, state.remainingTokens, verySmallEthAmount, K);
//         console.log("Tokens for 1 wei purchase:", verySmallTokens);
//         assertTrue(verySmallTokens > 0, "Should be able to purchase tokens with 1 wei");

//         console.log("--- Ending testSmallTokenPurchase ---\n");
//     }

//     function testCalculateEthForSpecificTokenAmount() public {
//         console.log("\n--- Starting testCalculateEthForSpecificTokenAmount ---");

//         uint256[] memory tokenAmounts = new uint256[](4);
//         tokenAmounts[0] = 1000 * 1e18; // 1,000 tokens
//         tokenAmounts[1] = 10000 * 1e18; // 10,000 tokens
//         tokenAmounts[2] = 100000 * 1e18; // 100,000 tokens
//         tokenAmounts[3] = 500000 * 1e18; // 500,000 tokens

//         for (uint256 i = 0; i < tokenAmounts.length; i++) {
//             console.log("\nCalculating ETH for", tokenAmounts[i], "tokens");

//             uint256 calculatedEthAmount = BondingCurveLib.calculateEthAmountForTokens(
//                 state.totalEthCollected, state.remainingTokens, tokenAmounts[i], K
//             );
//             console.log("Calculated ETH amount:", calculatedEthAmount);

//             // Verify by calculating tokens for the calculated ETH amount
//             uint256 verificationTokens = BondingCurveLib.calculateTokenAmount(
//                 state.totalEthCollected, state.remainingTokens, calculatedEthAmount, K
//             );
//             console.log("Verification tokens:", verificationTokens);

//             assertApproxEqRel(verificationTokens, tokenAmounts[i], 1e15, "ETH calculation verification mismatch");

//             // Update state to simulate purchase
//             state.totalEthCollected += calculatedEthAmount;
//             state.remainingTokens -= tokenAmounts[i];

//             console.log("Updated total ETH collected:", state.totalEthCollected);
//             console.log("Updated remaining tokens:", state.remainingTokens);
//         }

//         console.log("--- Ending testCalculateEthForSpecificTokenAmount ---\n");
//     }

//     function testEdgeCaseScenarios() public {
//         console.log("\n--- Starting testEdgeCaseScenarios ---");

//         // Test case 1: Purchase with 0 ETH
//         console.log("\nTest case 1: Purchase with 0 ETH");
//         uint256 zeroEthTokens =
//             BondingCurveLib.calculateTokenAmount(state.totalEthCollected, state.remainingTokens, 0, K);
//         console.log("Tokens for 0 ETH purchase:", zeroEthTokens);
//         assertEq(zeroEthTokens, 0, "Should receive 0 tokens for 0 ETH");

//         // Test case 2: Purchase all remaining tokens
//         console.log("\nTest case 2: Purchase all remaining tokens");
//         uint256 ethForAllTokens = BondingCurveLib.calculateEthAmountForTokens(
//             state.totalEthCollected, state.remainingTokens, state.remainingTokens, K
//         );
//         console.log("ETH required to purchase all remaining tokens:", ethForAllTokens);
//         uint256 allTokensPurchased =
//             BondingCurveLib.calculateTokenAmount(state.totalEthCollected, state.remainingTokens, ethForAllTokens, K);
//         console.log("Tokens purchased with calculated ETH:", allTokensPurchased);
//         assertApproxEqRel(
//             allTokensPurchased, state.remainingTokens, 1e15, "Should be able to purchase all remaining tokens"
//         );

//         // Test case 3: Attempt to purchase more than remaining tokens
//         console.log("\nTest case 3: Attempt to purchase more than remaining tokens");
//         uint256 excessTokens = state.remainingTokens + 1000 * 1e18;
//         vm.expectRevert();
//         BondingCurveLib.calculateEthAmountForTokens(state.totalEthCollected, state.remainingTokens, excessTokens, K);
//         console.log("Correctly reverted when attempting to purchase more than remaining tokens");

//         // Test case 4: Purchase with very large ETH amount
//         console.log("\nTest case 4: Purchase with very large ETH amount");
//         uint256 veryLargeEthAmount = 1_000_000 ether;
//         uint256 tokensForLargeEth =
//             BondingCurveLib.calculateTokenAmount(state.totalEthCollected, state.remainingTokens, veryLargeEthAmount, K);
//         console.log("Tokens for very large ETH purchase:", tokensForLargeEth);
//         assertTrue(
//             tokensForLargeEth < state.remainingTokens, "Should not be able to purchase more than remaining tokens"
//         );

//         // Test case 5: Verify K constant remains unchanged
//         console.log("\nTest case 5: Verify K constant remains unchanged");
//         uint256 initialK = state.totalEthCollected * state.remainingTokens;
//         uint256 purchaseAmount = 10 ether;
//         uint256 tokensPurchased =
//             BondingCurveLib.calculateTokenAmount(state.totalEthCollected, state.remainingTokens, purchaseAmount, K);
//         uint256 newK = (state.totalEthCollected + purchaseAmount) * (state.remainingTokens - tokensPurchased);
//         console.log("Initial K:", initialK);
//         console.log("New K after purchase:", newK);
//         assertApproxEqRel(initialK, newK, 1e15, "K should remain constant");

//         console.log("--- Ending testEdgeCaseScenarios ---\n");
//     }

//     // Helper function to calculate expected tokens (hardcoded calculation)
//     function calculateExpectedTokens(uint256 totalEthCollected, uint256 remainingTokens, uint256 ethAmount)
//         internal
//         pure
//         returns (uint256)
//     {
//         // Manual implementation of the bonding curve formula
//         uint256 newEthReserve = totalEthCollected + ethAmount;
//         uint256 newTokenSupply = (K * PRECISION) / newEthReserve;
//         return remainingTokens - (newTokenSupply / PRECISION);
//     }
// }
