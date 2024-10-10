// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.19;

// import {Test, console} from "forge-std/Test.sol";
// import {CustomToken} from "../../src/customToken.sol";
// import {DeployKannonV1} from "../../script/deployKannonV1.s.sol";
// import {KannonV1} from "../../src/kannon_v1.sol";
// import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
// import {BondingCurveLib} from "../../src/kannon_v1_bonding_curve.sol";
// import {KannonV1Library} from "../../src/kannon_v1_library.sol";

// contract KannonV1TestIntermediatePresale is Test {
//     KannonV1 public kannonV1;
//     address public deployer;
//     address public user1;
//     address public user2;
//     address public user3;
//     address public tokenAddress;

//     uint256 constant INITIAL_SUPPLY = 1000000000 * 1e18; // 1 billion tokens
//     uint256 constant ETH_TARGET = 100 ether;
//     uint256 constant PRESALE_DURATION = 7 days;

//     function setUp() public {
//         console.log("Setting up test environment");
//         deployer = makeAddr("deployer");
//         user1 = makeAddr("user1");
//         user2 = makeAddr("user2");
//         user3 = makeAddr("user3");
//         vm.deal(user1, 10000000000000 ether);
//         vm.deal(user2, 1000000000000 ether);
//         vm.deal(user3, 10000000000000 ether);

//         DeployKannonV1 deployScript = new DeployKannonV1();
//         (kannonV1,) = deployScript.run();
//         tokenAddress = createTokenAndStartPresale();
//         console.log("Token created at address:", tokenAddress);
//     }

//     function createTokenAndStartPresale() internal returns (address) {
//         console.log("Creating token and starting presale");
//         vm.prank(deployer);
//         return kannonV1.createTokenAndStartPresale(
//             "Test Token",
//             "TEST",
//             "Test Description",
//             "http://test.com/image.png",
//             "http://twitter.com/test",
//             "http://t.me/test",
//             "http://test.com",
//             INITIAL_SUPPLY,
//             ETH_TARGET,
//             PRESALE_DURATION
//         );
//     }

//     function logReserveAndPriceInfo(
//         string memory label,
//         uint256 ethReserve,
//         uint256 tokenReserve,
//         uint256 price,
//         KannonV1.LaunchInfo memory launchInfo
//     ) internal {
//         uint256 intermediatePresaleDistributable = launchInfo.distributableSupply / 3;
//         uint256 remainingTokensDistributable =
//             launchInfo.distributableSupply - launchInfo.totalPresoldTokens - launchInfo.distributableSupply / 3;
//         console.log("--- ---- ------ ------- ------- ------ -----");
//         console.log("--- ---- ------ ------- ------- ------ -----");

//         console.log("--- ---- ------ ------- ------- ------ -----");

//         console.log("---", label, "---");
//         console.log("ETH Reserve:   ", ethReserve);
//         console.log("Token Reserve: ", tokenReserve);
//         console.log("Distributable Intermidiate token: ", remainingTokensDistributable);
//         console.log("Total Token presold: ", launchInfo.totalPresoldTokens);
//         console.log("Price (wei/token): ", price);
//         console.log("current phase", uint256(launchInfo.currentPhase));
//         console.log("--- ---- ------ ------- ------- ------ -----");
//         console.log("--- ---- ------ ------- ------- ------ -----");
//         console.log("--- ---- ------ ------- ------- ------ -----");
//     }

//     function logPriceIncrease(uint256 oldPrice, uint256 newPrice) internal {
//         if (oldPrice == 0) {
//             console.log("Price increase: N/A (initial price was 0)");
//             return;
//         }

//         if (newPrice <= oldPrice) {
//             console.log("Price increase: 0 (no increase)");
//             return;
//         }

//         uint256 increase = newPrice - oldPrice;
//         uint256 percentageIncrease = (increase * 10000) / oldPrice;
//         uint256 wholePart = percentageIncrease / 100;
//         uint256 fractionalPart = percentageIncrease % 100;

//         console.log("Price increase:     ", increase);

//         if (fractionalPart < 10) {
//             console.log("Percentage increase: %s.0%s%%", wholePart, fractionalPart);
//         } else {
//             console.log("Percentage increase: %s.%s%%", wholePart, fractionalPart);
//         }
//     }

//     function testTransitionToIntermediatePresale() public {
//         // console.log("Testing transition to intermediate presale");
//         uint256 distributableSupply = INITIAL_SUPPLY * 95 / 100;
//         uint256 initialPresaleTarget = distributableSupply / 3;
//         uint256 ethNeeded = ETH_TARGET; // Full ETH target is needed
//         uint256 ethBuffer = 0.1 ether;
//         uint256 totalEthSent = ethNeeded + ethBuffer;

//         // console.log("Distributable supply:", distributableSupply);
//         // console.log("Initial presale target:", initialPresaleTarget);
//         // console.log("ETH needed:", ethNeeded);
//         // console.log("Total ETH sent:", totalEthSent);

//         uint256 user1BalanceBefore = user1.balance;
//         // console.log("User1 balance before:", user1BalanceBefore);

//         vm.prank(user1);
//         kannonV1.participateInPresale{value: totalEthSent}(tokenAddress);

//         KannonV1.LaunchInfo memory launchInfo = kannonV1.getLaunchInfo(tokenAddress);
//         // console.log("Current phase after participation:", uint256(launchInfo.currentPhase));
//         // console.log("Total presold tokens:", launchInfo.totalPresoldTokens);
//         // console.log("ETH collected:", launchInfo.ethCollected);

//         assertEq(
//             uint256(launchInfo.currentPhase),
//             uint256(KannonV1.LaunchPhase.IntermediatePresale),
//             "Should transition to IntermediatePresale"
//         );
//         assertEq(launchInfo.ethCollected, ethNeeded, "Collected ETH should match the needed amount");
//         assertApproxEqAbs(
//             launchInfo.totalPresoldTokens,
//             initialPresaleTarget,
//             1e15,
//             "Total presold tokens should approximately match initial presale target"
//         );

//         uint256 user1BalanceAfter = user1.balance;
//         console.log("User1 balance after:", user1BalanceAfter);
//         assertApproxEqAbs(user1BalanceAfter, user1BalanceBefore - ethNeeded, 1e15, "User should be refunded excess ETH");

//         // Participate again, now in intermediate phase
//         uint256 intermediateParticipationAmount = 1 ether;
//         uint256 user2BalanceBefore = user2.balance;
//         // console.log("User2 balance before intermediate participation:", user2BalanceBefore);

//         uint256 initialPrice =
//             BondingCurveLib.getTokenPrice(launchInfo.ethCollected, distributableSupply - launchInfo.totalPresoldTokens);
//         logReserveAndPriceInfo(
//             "Before Intermediate Participation",
//             launchInfo.ethCollected,
//             distributableSupply - launchInfo.totalPresoldTokens,
//             initialPrice,
//             launchInfo
//         );

//         vm.prank(user2);
//         kannonV1.participateInPresale{value: intermediateParticipationAmount}(tokenAddress);

//         KannonV1.LaunchInfo memory updatedLaunchInfo = kannonV1.getLaunchInfo(tokenAddress);
//         uint256 user2TokensReceived = kannonV1.userPresale(tokenAddress, user2);

//         uint256 newPrice = BondingCurveLib.getTokenPrice(
//             updatedLaunchInfo.ethCollected, distributableSupply - updatedLaunchInfo.totalPresoldTokens
//         );
//         logReserveAndPriceInfo(
//             "After Intermediate Participation",
//             updatedLaunchInfo.ethCollected,
//             distributableSupply - updatedLaunchInfo.totalPresoldTokens,
//             newPrice,
//             updatedLaunchInfo
//         );
//         logPriceIncrease(initialPrice, newPrice);

//         console.log("Tokens received by User2 in intermediate phase:", user2TokensReceived);
//         console.log("Updated ETH collected:", updatedLaunchInfo.ethCollected);
//         console.log("Updated total presold tokens:", updatedLaunchInfo.totalPresoldTokens);

//         assertTrue(user2TokensReceived > 0, "User should receive tokens in intermediate phase");
//         assertTrue(updatedLaunchInfo.ethCollected > launchInfo.ethCollected, "More ETH should be collected");
//         assertTrue(
//             updatedLaunchInfo.totalPresoldTokens > launchInfo.totalPresoldTokens, "More tokens should be presold"
//         );

//         // Participate again with a smaller amount to check price increase
//         uint256 secondParticipationAmount = 0.5 ether;
//         vm.prank(user2);
//         kannonV1.participateInPresale{value: secondParticipationAmount}(tokenAddress);

//         KannonV1.LaunchInfo memory finalInfo = kannonV1.getLaunchInfo(tokenAddress);
//         uint256 totalUser2Tokens = kannonV1.userPresale(tokenAddress, user2);
//         uint256 secondParticipationTokens = totalUser2Tokens - user2TokensReceived;

//         uint256 finalPrice =
//             BondingCurveLib.getTokenPrice(finalInfo.ethCollected, distributableSupply - finalInfo.totalPresoldTokens);
//         logReserveAndPriceInfo(
//             "After Second Participation",
//             finalInfo.ethCollected,
//             distributableSupply - finalInfo.totalPresoldTokens,
//             finalPrice,
//             finalInfo
//         );
//         logPriceIncrease(newPrice, finalPrice);

//         console.log("Second participation tokens:", secondParticipationTokens);
//         assertTrue(
//             secondParticipationTokens < user2TokensReceived,
//             "Second participation should yield fewer tokens due to price increase"
//         );

//         console.log("Final phase:", uint256(finalInfo.currentPhase));
//         console.log("Final ETH collected:", finalInfo.ethCollected);
//         console.log("Final total presold tokens:", finalInfo.totalPresoldTokens);

//         assertEq(
//             uint256(finalInfo.currentPhase),
//             uint256(KannonV1.LaunchPhase.IntermediatePresale),
//             "Should still be in IntermediatePresale"
//         );
//         assertTrue(
//             finalInfo.ethCollected > ethNeeded + intermediateParticipationAmount + secondParticipationAmount - 1e15,
//             "Total ETH collected should be close to expected"
//         );
//     }

//     function testTransitionToFinalLaunchFromIntermediate() public {
//         console.log("Testing transition to final launch from intermediate");
//         testTransitionToIntermediatePresale();

//         KannonV1.LaunchInfo memory initialInfo = kannonV1.getLaunchInfo(tokenAddress);
//         console.log("Initial total presold tokens:", initialInfo.totalPresoldTokens);
//         uint256 distributableSupply = initialInfo.distributableSupply;

//         uint256 remainingTokensDistributable =
//             initialInfo.distributableSupply - initialInfo.totalPresoldTokens - initialInfo.distributableSupply / 3;
//         uint256 tokenAmountForPrice = distributableSupply - initialInfo.totalPresoldTokens;
//         uint256 ethNeeded = BondingCurveLib.calculateEthAmountForTokens(
//             initialInfo.ethCollected, tokenAmountForPrice, remainingTokensDistributable, initialInfo.k
//         );

//         console.log("ETH needed to reach final launch:", ethNeeded);
//         uint256 ethBuffer = 100 ether;
//         uint256 totalEthSent = ethNeeded + ethBuffer;

//         uint256 initialPrice = BondingCurveLib.getTokenPrice(
//             initialInfo.ethCollected, distributableSupply - initialInfo.totalPresoldTokens
//         );
//         logReserveAndPriceInfo(
//             "Before Final Launch Transition",
//             initialInfo.ethCollected,
//             distributableSupply - initialInfo.totalPresoldTokens,
//             initialPrice,
//             initialInfo
//         );

//         uint256 user2BalanceBefore = user2.balance;
//         console.log("User2 balance before:", user2BalanceBefore);

//         vm.prank(user2);
//         kannonV1.participateInPresale{value: totalEthSent}(tokenAddress);

//         KannonV1.LaunchInfo memory finalInfo = kannonV1.getLaunchInfo(tokenAddress);
//         uint256 finalPrice =
//             BondingCurveLib.getTokenPrice(finalInfo.ethCollected, distributableSupply - finalInfo.totalPresoldTokens);
//         logReserveAndPriceInfo(
//             "After Final Launch Transition",
//             finalInfo.ethCollected,
//             distributableSupply - finalInfo.totalPresoldTokens,
//             finalPrice,
//             finalInfo
//         );
//         logPriceIncrease(initialPrice, finalPrice);

//         console.log("Current phase after participation:", uint256(finalInfo.currentPhase));

//         assertEq(
//             uint256(finalInfo.currentPhase),
//             uint256(KannonV1.LaunchPhase.FinalLaunch),
//             "Should transition to FinalLaunch"
//         );

//         console.log("Final ETH collected:", finalInfo.ethCollected);
//         assertApproxEqAbs(
//             finalInfo.ethCollected,
//             initialInfo.ethCollected + ethNeeded,
//             1e15,
//             "Collected ETH should approximately match the needed amount"
//         );

//         uint256 user2BalanceAfter = user2.balance;
//         console.log("User2 balance after:", user2BalanceAfter);
//         assertApproxEqAbs(user2BalanceAfter, user2BalanceBefore - ethNeeded, 1e15, "User should be refunded excess ETH");

//         console.log("Final total presold tokens:", finalInfo.totalPresoldTokens);
//         assertApproxEqAbs(
//             finalInfo.totalPresoldTokens,
//             distributableSupply * 2 / 3,
//             1e15,
//             "Total presold tokens should approximately match 2/3 of distributable supply"
//         );

//         uint256 user2PresaleBalance = kannonV1.userPresale(tokenAddress, user2);
//         console.log("User2 presale balance:", user2PresaleBalance);
//         assertApproxEqAbs(
//             user2PresaleBalance,
//             remainingTokensDistributable,
//             1e15,
//             "User's presale balance should approximately match the target amount"
//         );
//     }

//     function testDeadlineReachedDuringIntermediate() public {
//         console.log("Testing deadline reached during intermediate presale");
//         testTransitionToIntermediatePresale();

//         KannonV1.LaunchInfo memory initialInfo = kannonV1.getLaunchInfo(tokenAddress);
//         uint256 distributableSupply = INITIAL_SUPPLY * 95 / 100;
//         uint256 initialPrice = BondingCurveLib.getTokenPrice(
//             initialInfo.ethCollected, distributableSupply - initialInfo.totalPresoldTokens
//         );
//         logReserveAndPriceInfo(
//             "Before Deadline",
//             initialInfo.ethCollected,
//             distributableSupply - initialInfo.totalPresoldTokens,
//             initialPrice,
//             initialInfo
//         );
//         vm.prank(user2);
//         kannonV1.participateInPresale{value: 1 ether}(tokenAddress);
//         console.log("Fast forwarding time to after deadline");
//         vm.warp(block.timestamp + PRESALE_DURATION + 1);

//         vm.prank(user3);

//         kannonV1.participateInPresale{value: 1 ether}(tokenAddress);
//         console.log("Participation after deadline failed as expected");
//         vm.prank(user1);
//         vm.expectRevert(KannonV1Library.KannonV1_InvalidPhase.selector);
//         kannonV1.participateInPresale{value: 1 ether}(tokenAddress);
//         console.log("Participation after deadline failed as expected");
//         KannonV1.LaunchInfo memory finalInfo = kannonV1.getLaunchInfo(tokenAddress);
//         console.log("Current phase after deadline:", uint256(finalInfo.currentPhase));

//         uint256 finalPrice =
//             BondingCurveLib.getTokenPrice(finalInfo.ethCollected, distributableSupply - finalInfo.totalPresoldTokens);
//         logReserveAndPriceInfo(
//             "After Deadline",
//             finalInfo.ethCollected,
//             distributableSupply - finalInfo.totalPresoldTokens,
//             finalPrice,
//             finalInfo
//         );
//         logPriceIncrease(initialPrice, finalPrice);

//         assertEq(
//             uint256(finalInfo.currentPhase),
//             uint256(KannonV1.LaunchPhase.FinalLaunch),
//             "Should transition to FinalLaunch due to deadline"
//         );
//     }

//     function testMultipleParticipationsInIntermediate() public {
//         console.log("Testing multiple participations in intermediate presale");
//         testTransitionToIntermediatePresale();

//         uint256 participation1 = 1 ether;
//         uint256 participation2 = 2 ether;

//         KannonV1.LaunchInfo memory initialInfo = kannonV1.getLaunchInfo(tokenAddress);
//         uint256 distributableSupply = INITIAL_SUPPLY * 95 / 100;
//         uint256 initialPrice = BondingCurveLib.getTokenPrice(
//             initialInfo.ethCollected, distributableSupply - initialInfo.totalPresoldTokens
//         );
//         logReserveAndPriceInfo(
//             "Initial State",
//             initialInfo.ethCollected,
//             distributableSupply - initialInfo.totalPresoldTokens,
//             initialPrice,
//             initialInfo
//         );

//         console.log("User2 first participation:", participation1);
//         vm.prank(user2);
//         kannonV1.participateInPresale{value: participation1}(tokenAddress);

//         KannonV1.LaunchInfo memory midInfo = kannonV1.getLaunchInfo(tokenAddress);
//         uint256 midPrice =
//             BondingCurveLib.getTokenPrice(midInfo.ethCollected, distributableSupply - midInfo.totalPresoldTokens);
//         logReserveAndPriceInfo(
//             "After First Participation",
//             midInfo.ethCollected,
//             distributableSupply - midInfo.totalPresoldTokens,
//             midPrice,
//             midInfo
//         );
//         logPriceIncrease(initialPrice, midPrice);

//         console.log("User2 second participation:", participation2);
//         vm.prank(user2);
//         kannonV1.participateInPresale{value: participation2}(tokenAddress);

//         KannonV1.LaunchInfo memory finalInfo = kannonV1.getLaunchInfo(tokenAddress);
//         uint256 finalPrice =
//             BondingCurveLib.getTokenPrice(finalInfo.ethCollected, distributableSupply - finalInfo.totalPresoldTokens);
//         logReserveAndPriceInfo(
//             "After Second Participation",
//             finalInfo.ethCollected,
//             distributableSupply - finalInfo.totalPresoldTokens,
//             finalPrice,
//             finalInfo
//         );
//         logPriceIncrease(midPrice, finalPrice);

//         uint256 actualTokens = kannonV1.userPresale(tokenAddress, user2);
//         console.log("Total tokens for User2:", actualTokens);

//         assertTrue(actualTokens > 0, "User2 should receive tokens");
//         assertTrue(finalInfo.ethCollected > midInfo.ethCollected, "ETH collected should increase");
//         assertTrue(finalInfo.totalPresoldTokens > midInfo.totalPresoldTokens, "Total presold tokens should increase");
//         assertTrue(finalPrice > midPrice, "Token price should increase after second participation");
//     }

//     function testRefundExcessEthInIntermediate() public {
//         testTransitionToIntermediatePresale();

//         KannonV1.LaunchInfo memory initialInfo = kannonV1.getLaunchInfo(tokenAddress);
//         uint256 distributableSupply = initialInfo.distributableSupply;
//         uint256 remainingTokens = distributableSupply - initialInfo.totalPresoldTokens - distributableSupply / 4;

//         uint256 tokenAmountForPrice = distributableSupply - initialInfo.totalPresoldTokens;
//         uint256 maxEthAccepted = BondingCurveLib.calculateEthAmountForTokens(
//             initialInfo.ethCollected, tokenAmountForPrice, remainingTokens, initialInfo.k
//         );
//         uint256 excessEth = 1 ether;
//         uint256 totalEthSent = maxEthAccepted + excessEth;

//         // uint256 initialPrice = BondingCurveLib.getTokenPrice(initialInfo.ethCollected, remainingTokens);
//         // logReserveAndPriceInfo("Initial State", initialInfo.ethCollected, remainingTokens, initialPrice, initialInfo);

//         console.log("Max ETH accepted:", maxEthAccepted);
//         console.log("Total ETH sent:", totalEthSent);

//         uint256 userBalance = user3.balance;
//         vm.prank(user3);
//         kannonV1.participateInPresale{value: totalEthSent}(tokenAddress);

//         uint256 userBalanceAfter = user3.balance;
//         // console.log("User3 balance before:", userBalance);
//         // console.log("User3 balance after:", userBalanceAfter);
//         assertEq(userBalanceAfter, userBalance - maxEthAccepted, "User3 should be refunded excess ETH");

//         KannonV1.LaunchInfo memory finalInfo = kannonV1.getLaunchInfo(tokenAddress);
//         // uint256 finalPrice =
//         //     BondingCurveLib.getTokenPrice(finalInfo.ethCollected, distributableSupply - finalInfo.totalPresoldTokens);
//         // logReserveAndPriceInfo(
//         //     "Final State",
//         //     finalInfo.ethCollected,
//         //     distributableSupply - finalInfo.totalPresoldTokens,
//         //     finalPrice,
//         //     finalInfo
//         // );
//         // logPriceIncrease(initialPrice, finalPrice);

//         // console.log("Final ETH collected:", finalInfo.ethCollected);
//         assertEq(
//             finalInfo.ethCollected, initialInfo.ethCollected + maxEthAccepted, "Correct ETH amount should be collected"
//         );

//         // console.log("Final total presold tokens:", finalInfo.totalPresoldTokens);
//         // assertEq(finalInfo.totalPresoldTokens, distributableSupply, "All tokens should be sold");

//         // console.log("Final phase:", uint256(finalInfo.currentPhase));
//         assertEq(
//             uint256(finalInfo.currentPhase),
//             uint256(KannonV1.LaunchPhase.FinalLaunch),
//             "Should transition to FinalLaunch"
//         );
//     }

//     function testBondingCurvePriceIncrease() public {
//         console.log("Testing bonding curve price increase");
//         testTransitionToIntermediatePresale();

//         uint256 initialEthAmount = 0.1 ether;
//         uint256 subsequentEthAmount = 0.1 ether;

//         KannonV1.LaunchInfo memory initialInfo = kannonV1.getLaunchInfo(tokenAddress);
//         uint256 distributableSupply = INITIAL_SUPPLY * 95 / 100;
//         uint256 initialPrice = BondingCurveLib.getTokenPrice(
//             initialInfo.ethCollected, distributableSupply - initialInfo.totalPresoldTokens
//         );
//         logReserveAndPriceInfo(
//             "Initial State",
//             initialInfo.ethCollected,
//             distributableSupply - initialInfo.totalPresoldTokens,
//             initialPrice,
//             initialInfo
//         );

//         console.log("Initial participation");
//         vm.prank(user2);
//         kannonV1.participateInPresale{value: initialEthAmount}(tokenAddress);

//         KannonV1.LaunchInfo memory midInfo = kannonV1.getLaunchInfo(tokenAddress);
//         uint256 initialTokens = kannonV1.userPresale(tokenAddress, user2);
//         uint256 midPrice =
//             BondingCurveLib.getTokenPrice(midInfo.ethCollected, distributableSupply - midInfo.totalPresoldTokens);
//         logReserveAndPriceInfo(
//             "After Initial Participation",
//             midInfo.ethCollected,
//             distributableSupply - midInfo.totalPresoldTokens,
//             midPrice,
//             midInfo
//         );
//         logPriceIncrease(initialPrice, midPrice);
//         console.log("Initial tokens received:", initialTokens);

//         console.log("Subsequent participation");
//         vm.prank(user2);
//         kannonV1.participateInPresale{value: subsequentEthAmount}(tokenAddress);

//         KannonV1.LaunchInfo memory finalInfo = kannonV1.getLaunchInfo(tokenAddress);
//         uint256 totalTokens = kannonV1.userPresale(tokenAddress, user2);
//         uint256 subsequentTokens = totalTokens - initialTokens;
//         uint256 finalPrice =
//             BondingCurveLib.getTokenPrice(finalInfo.ethCollected, distributableSupply - finalInfo.totalPresoldTokens);
//         logReserveAndPriceInfo(
//             "After Subsequent Participation",
//             finalInfo.ethCollected,
//             distributableSupply - finalInfo.totalPresoldTokens,
//             finalPrice,
//             finalInfo
//         );
//         logPriceIncrease(midPrice, finalPrice);
//         console.log("Subsequent tokens received:", subsequentTokens);

//         assertLt(
//             subsequentTokens, initialTokens, "Subsequent participation should yield fewer tokens due to price increase"
//         );
//         console.log("Price increase confirmed: Initial tokens > Subsequent tokens");
//     }

//     function testBondingCurveCalculations() public {
//         console.log("Testing bonding curve calculations");
//         testTransitionToIntermediatePresale();

//         KannonV1.LaunchInfo memory launchInfo = kannonV1.getLaunchInfo(tokenAddress);
//         uint256 distributableSupply = INITIAL_SUPPLY * 95 / 100;
//         uint256 remainingTokens = distributableSupply - launchInfo.totalPresoldTokens;
//         uint256 ethAmount = 1 ether;

//         uint256 initialPrice = BondingCurveLib.getTokenPrice(launchInfo.ethCollected, remainingTokens);
//         logReserveAndPriceInfo("Initial State", launchInfo.ethCollected, remainingTokens, initialPrice, launchInfo);

//         uint256 calculatedTokens =
//             BondingCurveLib.calculateTokenAmount(launchInfo.ethCollected, remainingTokens, ethAmount, launchInfo.k);
//         console.log("Calculated tokens for 1 ETH:", calculatedTokens);

//         uint256 calculatedEth = BondingCurveLib.calculateEthAmountForTokens(
//             launchInfo.ethCollected, remainingTokens, calculatedTokens, launchInfo.k
//         );
//         console.log("Calculated ETH for tokens:", calculatedEth);

//         uint256 finalPrice =
//             BondingCurveLib.getTokenPrice(launchInfo.ethCollected + calculatedEth, remainingTokens - calculatedTokens);
//         logReserveAndPriceInfo(
//             "After Calculation",
//             launchInfo.ethCollected + calculatedEth,
//             remainingTokens - calculatedTokens,
//             finalPrice,
//             launchInfo
//         );
//         logPriceIncrease(initialPrice, finalPrice);

//         assertApproxEqAbs(calculatedEth, ethAmount, 1e15, "Calculated ETH should approximately match input ETH");
//         console.log("Bonding curve calculations consistency confirmed");
//     }

//     function testPriceIncreaseInIntermediatePresale() public {
//         console.log("Testing price increase in intermediate presale");
//         testTransitionToIntermediatePresale();

//         KannonV1.LaunchInfo memory initialInfo = kannonV1.getLaunchInfo(tokenAddress);
//         uint256 distributableSupply = initialInfo.distributableSupply;
//         uint256 ethTarget = initialInfo.ethTarget;
//         uint256 remainingTokens = distributableSupply - initialInfo.totalPresoldTokens;

//         console.log("Initial ETH collected:", initialInfo.ethCollected);
//         console.log("Initial tokens sold:", initialInfo.totalPresoldTokens);
//         console.log("Remaining tokens:", remainingTokens);

//         uint256 initialPrice = BondingCurveLib.getTokenPrice(initialInfo.ethCollected, remainingTokens);
//         console.log("Initial price (wei/token):", initialPrice);

//         for (uint256 i = 10; i <= 100; i += 10) {
//             uint256 ethAmount = (ethTarget * i) / 100;
//             console.log("--- Buying with %s wei (%s%% of ETH target) ---", ethAmount, i);

//             vm.prank(user3);
//             kannonV1.participateInPresale{value: ethAmount}(tokenAddress);

//             KannonV1.LaunchInfo memory updatedInfo = kannonV1.getLaunchInfo(tokenAddress);
//             uint256 tokensBought = updatedInfo.totalPresoldTokens - initialInfo.totalPresoldTokens;
//             uint256 newPrice = BondingCurveLib.getTokenPrice(
//                 updatedInfo.ethCollected, distributableSupply - updatedInfo.totalPresoldTokens
//             );

//             console.log("ETH spent:", ethAmount);
//             console.log("Tokens bought:", tokensBought);
//             console.log("New price (wei/token):", newPrice);
//             console.log("Price increase:", newPrice - initialPrice);
//             console.log("Percentage increase: ", ((newPrice - initialPrice) * 100 * 1e18) / initialPrice / 1e16, "%");

//             initialInfo = updatedInfo;
//             initialPrice = newPrice;

//             if (updatedInfo.currentPhase == KannonV1.LaunchPhase.FinalLaunch) {
//                 console.log("\nTransitioned to Final Launch phase. Stopping test.");
//                 break;
//             }
//         }

//         KannonV1.LaunchInfo memory finalInfo = kannonV1.getLaunchInfo(tokenAddress);
//         console.log("\nFinal state:");
//         console.log("Total ETH collected:", finalInfo.ethCollected);
//         console.log("Total tokens sold:", finalInfo.totalPresoldTokens);
//         console.log(
//             "Final price (wei/token):",
//             BondingCurveLib.getTokenPrice(finalInfo.ethCollected, distributableSupply - finalInfo.totalPresoldTokens)
//         );
//         console.log("Current phase:", uint256(finalInfo.currentPhase));
//     }
// }
