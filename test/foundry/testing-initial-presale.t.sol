// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.19;

// import {Test, console} from "forge-std/Test.sol";
// import {CustomToken} from "../../src/customToken.sol";
// import {DeployKannonV1} from "../../script/deployKannonV1.s.sol";
// import {KannonV1} from "../../src/kannon_v1.sol";
// import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
// import {KannonV1Library} from "../../src/kannon_v1_library.sol";

// contract KannonV1TestInitialPresale is Test {
//     KannonV1 public kannonV1;
//     address public user1;
//     address public user2;
//     address public deployer;
//     // address public tokenAddress;

//     uint256 constant INITIAL_SUPPLY = 1000000000 * 1e18; // 1 million tokens
//     uint256 constant ETH_TARGET = 100 ether;
//     uint256 constant PRESALE_DURATION = 7 days;

//     function setUp() public {
//         deployer = makeAddr("deployer");
//         user1 = makeAddr("user1");
//         user2 = makeAddr("user2");

//         vm.deal(user1, 100 ether);
//         vm.deal(user2, 100 ether);

//         DeployKannonV1 deployScript = new DeployKannonV1();
//         (kannonV1,) = deployScript.run();
//     }

//     function createTokenAndStartPresale() public returns (address) {
//         vm.startPrank(deployer);

//         console.log("Creating token and starting presale...");
//         address tokenAddress = kannonV1.createTokenAndStartPresale(
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
//         console.log("Token created at address:", tokenAddress);

//         vm.stopPrank();

//         // Check if the token was created and presale started correctly
//         KannonV1.LaunchInfo memory launchInfo = kannonV1.getLaunchInfo(tokenAddress);
//         console.log("Checking launch info...");
//         assertEq(launchInfo.creator, deployer, "Creator should be the deployer");
//         assertEq(
//             uint256(launchInfo.currentPhase),
//             uint256(KannonV1.LaunchPhase.InitialPresale),
//             "Current phase should be InitialPresale"
//         );
//         assertEq(
//             launchInfo.launchDeadline, block.timestamp + PRESALE_DURATION, "Launch deadline should be set correctly"
//         );
//         assertEq(
//             launchInfo.distributableSupply,
//             INITIAL_SUPPLY * 95 / 100,
//             "Distributable supply should be 95% of initial supply"
//         );
//         uint256 initialPresaleDistributable = launchInfo.distributableSupply / 3;
//         assertEq(launchInfo.ethTarget, ETH_TARGET, "ETH target should be set correctly");
//         assertEq(launchInfo.ethCollected, 0, "ETH collected should be 0 initially");
//         assertEq(
//             initialPresaleDistributable,
//             INITIAL_SUPPLY * 95 / 100 / 3,
//             "Initial presale tokens should be 1/3 of distributable supply"
//         );

//         assertEq(launchInfo.totalPresoldTokens, 0, "Total presold tokens should be 0 initially");
//         console.log("Launch info checks passed");

//         return tokenAddress;
//     }

//     function testCreateTokenAndStartPresaleOnly() public {
//         address tokenAddress = createTokenAndStartPresale();
//     }

//     function participateInPresale() public returns (address) {
//         address tokenAddress = createTokenAndStartPresale();
//         // Check if participation was recorded correctly
//         KannonV1.LaunchInfo memory launchInfo = kannonV1.getLaunchInfo(tokenAddress);
//         uint256 participationAmount = 1 ether;
//         uint256 initialPresaleDistributable = launchInfo.distributableSupply / 3;
//         uint256 expectedTokens = participationAmount * initialPresaleDistributable / ETH_TARGET;

//         console.log("User1 participating in presale with", participationAmount, "ETH");
//         vm.startPrank(user1);
//         kannonV1.participateInPresale{value: participationAmount}(tokenAddress);
//         vm.stopPrank();

//         console.log("Checking presale participation...");
//         assertEq(launchInfo.ethCollected, participationAmount, "ETH collected should match participation amount");
//         assertEq(launchInfo.totalPresoldTokens, expectedTokens, "Total presold tokens should match expected amount");
//         assertEq(
//             kannonV1.userPresale(tokenAddress, user1),
//             expectedTokens,
//             "User1's presale tokens should match expected amount"
//         );
//         console.log("Presale participation checks passed");
//         return tokenAddress;
//     }

//     function testParticipateInPresaleOnly() public {
//         address tokenAddress = participateInPresale();
//     }

//     function testParticipateInPresaleMultipleUsersOnly() public {
//         address tokenAddress = createTokenAndStartPresale();
//         KannonV1.LaunchInfo memory launchInfo = kannonV1.getLaunchInfo(tokenAddress);
//         uint256 participationAmount1 = 1 ether;
//         uint256 participationAmount2 = 2 ether;
//         uint256 initialPresaleDistributable = launchInfo.distributableSupply / 3;
//         uint256 expectedTokens1 = participationAmount1 * initialPresaleDistributable / ETH_TARGET;
//         uint256 expectedTokens2 = participationAmount2 * initialPresaleDistributable / ETH_TARGET;

//         console.log("User1 participating with", participationAmount1, "ETH");
//         vm.prank(user1);
//         kannonV1.participateInPresale{value: participationAmount1}(tokenAddress);

//         console.log("User2 participating with", participationAmount2, "ETH");
//         vm.prank(user2);
//         kannonV1.participateInPresale{value: participationAmount2}(tokenAddress);

//         // Check if participations were recorded correctly

//         console.log("Checking multiple user presale participation...");
//         assertEq(
//             launchInfo.ethCollected,
//             participationAmount1 + participationAmount2,
//             "Total ETH collected should match sum of participations"
//         );
//         assertEq(
//             launchInfo.totalPresoldTokens,
//             expectedTokens1 + expectedTokens2,
//             "Total presold tokens should match sum of expected tokens"
//         );
//         assertEq(
//             kannonV1.userPresale(tokenAddress, user1),
//             expectedTokens1,
//             "User1's presale tokens should match expected amount"
//         );
//         assertEq(
//             kannonV1.userPresale(tokenAddress, user2),
//             expectedTokens2,
//             "User2's presale tokens should match expected amount"
//         );
//         console.log("Multiple user presale participation checks passed");
//     }

//     function testParticipateInPresaleAfterDeadlineOnly() public {
//         address tokenAddress = createTokenAndStartPresale();

//         console.log("Moving time forward past the deadline");
//         vm.warp(block.timestamp + PRESALE_DURATION + 1);

//         console.log("Attempting to participate after deadline");
//         vm.expectRevert(KannonV1Library.KannonV1_DeadlineReached.selector);
//         vm.prank(user1);
//         kannonV1.participateInPresale{value: 1 ether}(tokenAddress);
//         console.log("Participation after deadline correctly reverted");
//     }

//     function testParticipateInPresaleWithZeroAmountOnly() public {
//         address tokenAddress = createTokenAndStartPresale();

//         console.log("Attempting to participate with zero amount");
//         vm.expectRevert(KannonV1Library.KannonV1_InsufficientFunds.selector);
//         vm.prank(user1);
//         kannonV1.participateInPresale{value: 0}(tokenAddress);
//         console.log("Participation with zero amount correctly reverted");
//     }

//     // function testParticipateInPresaleTransitionToIntermediatePhaseOnly() public {
//     //     address tokenAddress = createTokenAndStartPresale();

//     //     uint256 initialPresaleTokens = kannonV1.getLaunchInfo(tokenAddress).initialPresaleTokens;
//     //     uint256 participationAmount = ETH_TARGET * initialPresaleTokens / (INITIAL_SUPPLY * 95 / 100);

//     //     console.log("Participating with amount to trigger phase transition:", participationAmount);
//     //     vm.prank(user1);
//     //     kannonV1.participateInPresale{value: participationAmount}(tokenAddress);

//     //     KannonV1.LaunchInfo memory launchInfo = kannonV1.getLaunchInfo(tokenAddress);
//     //     console.log("Checking phase transition...");
//     //     assertEq(
//     //         uint256(launchInfo.currentPhase),
//     //         uint256(KannonV1.LaunchPhase.IntermediatePresale),
//     //         "Phase should transition to IntermediatePresale"
//     //     );
//     //     assertEq(
//     //         launchInfo.intermediatePresaleTokens, initialPresaleTokens, "Intermediate presale tokens should be set"
//     //     );
//     //     console.log("Phase transition checks passed");
//     // }

//     function testCompleteInitialPresaleApprox() public {
//         // First, create the token and start the presale
//         address tokenAddress = createTokenAndStartPresale();
//         console.log("Token created at address:", tokenAddress);

//         // Calculate the ETH amounts for each participation
//         KannonV1.LaunchInfo memory initialInfo = kannonV1.getLaunchInfo(tokenAddress);
//         uint256 totalEthTarget = initialInfo.ethTarget;
//         uint256 ethAmount1 = totalEthTarget / 4;
//         uint256 ethAmount2 = totalEthTarget / 3;
//         uint256 ethAmount3 = totalEthTarget / 5;
//         uint256 ethAmount4 = totalEthTarget - (ethAmount1 + ethAmount2 + ethAmount3) + 100;

//         console.log("ETH target:", totalEthTarget);
//         console.log("ETH amount 1:", ethAmount1);
//         console.log("ETH amount 2:", ethAmount2);
//         console.log("ETH amount 3:", ethAmount3);
//         console.log("ETH amount 4:", ethAmount4);

//         // Participate in presale four times
//         vm.deal(user1, ethAmount1);
//         vm.prank(user1);
//         kannonV1.participateInPresale{value: ethAmount1}(tokenAddress);
//         console.log("User1 participated with:", ethAmount1);

//         vm.deal(user2, ethAmount2);
//         vm.prank(user2);
//         kannonV1.participateInPresale{value: ethAmount2}(tokenAddress);
//         console.log("User2 participated with:", ethAmount2);

//         address user3 = makeAddr("user3");
//         vm.deal(user3, ethAmount3);
//         vm.prank(user3);
//         kannonV1.participateInPresale{value: ethAmount3}(tokenAddress);
//         console.log("User3 participated with:", ethAmount3);

//         address user4 = makeAddr("user4");
//         vm.deal(user4, ethAmount4);
//         vm.prank(user4);
//         kannonV1.participateInPresale{value: ethAmount4}(tokenAddress);
//         console.log("User4 participated with:", ethAmount4);

//         // Get the updated launch info
//         KannonV1.LaunchInfo memory launchInfo = kannonV1.getLaunchInfo(tokenAddress);

//         // Check if the total ETH collected matches the target
//         console.log("Total ETH collected:", launchInfo.ethCollected);
//         console.log("ETH target:", totalEthTarget);
//         assertApproxEqAbs(launchInfo.ethCollected, totalEthTarget, 1, "Total ETH collected should match the target");

//         // Check if the current phase has transitioned to IntermediatePresale
//         console.log("Current phase:", uint256(launchInfo.currentPhase));
//         console.log("this is the value for intermidiatestep", uint256(KannonV1.LaunchPhase.IntermediatePresale));
//         assertEq(uint256(launchInfo.currentPhase), uint256(1), "Phase should be IntermediatePresale");

//         // Check if the total presold tokens match the initialPresaleTokens
//         console.log("Total presold tokens:", launchInfo.totalPresoldTokens);
//         uint256 initialPresaleDistributable = launchInfo.distributableSupply / 3;
//         assertApproxEqAbs(
//             launchInfo.totalPresoldTokens,
//             initialPresaleDistributable,
//             1e6, // Allow for a difference of up to 1 token (assuming 18 decimals)
//             "Total presold tokens should approximately match initialPresaleTokens"
//         );

//         // Calculate and check individual token allocations
//         uint256 expectedTokens1 = ethAmount1 * initialPresaleDistributable / totalEthTarget;
//         uint256 expectedTokens2 = ethAmount2 * initialPresaleDistributable / totalEthTarget;
//         uint256 expectedTokens3 = ethAmount3 * initialPresaleDistributable / totalEthTarget;
//         uint256 expectedTokens4 = ethAmount4 * initialPresaleDistributable / totalEthTarget;

//         console.log("Expected tokens for User1:", expectedTokens1);
//         console.log("Expected tokens for User2:", expectedTokens2);
//         console.log("Expected tokens for User3:", expectedTokens3);
//         console.log("Expected tokens for User4:", expectedTokens4);

//         uint256 actualTokens1 = kannonV1.userPresale(tokenAddress, user1);
//         uint256 actualTokens2 = kannonV1.userPresale(tokenAddress, user2);
//         uint256 actualTokens3 = kannonV1.userPresale(tokenAddress, user3);
//         uint256 actualTokens4 = kannonV1.userPresale(tokenAddress, user4);

//         console.log("Actual tokens for User1:", actualTokens1);
//         console.log("Actual tokens for User2:", actualTokens2);
//         console.log("Actual tokens for User3:", actualTokens3);
//         console.log("Actual tokens for User4:", actualTokens4);

//         assertApproxEqAbs(actualTokens1, expectedTokens1, 1, "User1 token allocation incorrect");
//         assertApproxEqAbs(actualTokens2, expectedTokens2, 1, "User2 token allocation incorrect");
//         assertApproxEqAbs(actualTokens3, expectedTokens3, 1, "User3 token allocation incorrect");
//         assertApproxEqAbs(actualTokens4, expectedTokens4, 1, "User4 token allocation incorrect");

//         // Verify that the sum of all user presale tokens equals the total presold tokens
//         uint256 totalUserTokens = actualTokens1 + actualTokens2 + actualTokens3 + actualTokens4;
//         console.log("Sum of user tokens:", totalUserTokens);
//         console.log("Total presold tokens:", launchInfo.totalPresoldTokens);
//         assertApproxEqAbs(
//             totalUserTokens, launchInfo.totalPresoldTokens, 1, "Sum of user tokens should equal total presold tokens"
//         );

//         // Verify that the price remained approximately fixed throughout the initial presale
//         uint256 priceUser1 = actualTokens1 * totalEthTarget / initialPresaleDistributable;
//         uint256 priceUser4 = actualTokens4 * totalEthTarget / initialPresaleDistributable;
//         console.log("Price User1:", priceUser1);
//         console.log("ETH Amount1:", ethAmount1);
//         console.log("Price User4:", priceUser4);
//         console.log("ETH Amount4:", ethAmount4);
//         assertApproxEqAbs(priceUser1, ethAmount1, 1, "Price should remain approximately fixed for first participant");
//         assertApproxEqAbs(priceUser4, ethAmount4, 1, "Price should remain approximately fixed for last participant");

//         console.log("Initial presale completed successfully");
//         console.log("Total ETH collected:", launchInfo.ethCollected);
//         console.log("Total tokens presold:", launchInfo.totalPresoldTokens);
//         console.log("Current phase:", uint256(launchInfo.currentPhase));
//     }

//     function testParticipateInPresaleExceedingAvailableTokens() public {
//         // First, create the token and start the presale
//         address tokenAddress = createTokenAndStartPresale();
//         console.log("Token created at address:", tokenAddress);

//         // Get initial launch info
//         KannonV1.LaunchInfo memory initialInfo = kannonV1.getLaunchInfo(tokenAddress);
//         uint256 totalEthTarget = initialInfo.ethTarget;
//         uint256 initialPresaleDistributable = initialInfo.distributableSupply / 3;
//         uint256 availableTokens = initialPresaleDistributable;

//         // Participate with almost all available tokens
//         uint256 largeEthAmount = totalEthTarget * 99 / 100;
//         vm.deal(user1, largeEthAmount);
//         vm.prank(user1);
//         kannonV1.participateInPresale{value: largeEthAmount}(tokenAddress);

//         // Calculate remaining tokens and corresponding ETH
//         uint256 user1Tokens = kannonV1.userPresale(tokenAddress, user1);
//         uint256 remainingTokens = availableTokens - user1Tokens;
//         uint256 remainingEth = remainingTokens * totalEthTarget / availableTokens;

//         console.log("User1 tokens:", user1Tokens);
//         console.log("Remaining tokens:", remainingTokens);
//         console.log("Remaining ETH needed:", remainingEth);

//         // Try to participate with more tokens than available
//         uint256 excessEthAmount = totalEthTarget * 4 / 100; // This exceeds the remaining tokens
//         vm.deal(user2, excessEthAmount);
//         vm.prank(user2);

//         uint256 user2InitialBalance = user2.balance;
//         kannonV1.participateInPresale{value: excessEthAmount}(tokenAddress);

//         // Verify final state
//         KannonV1.LaunchInfo memory finalInfo = kannonV1.getLaunchInfo(tokenAddress);
//         uint256 user2Tokens = kannonV1.userPresale(tokenAddress, user2);
//         uint256 user2FinalBalance = user2.balance;

//         console.log("User2 tokens received:", user2Tokens);
//         console.log("User2 ETH refunded:", user2InitialBalance - user2FinalBalance);

//         // Assertions
//         assertEq(finalInfo.totalPresoldTokens, availableTokens, "Total presold tokens should equal available tokens");
//         assertEq(user2Tokens, remainingTokens, "User2 should receive the remaining tokens");
//         assertEq(finalInfo.ethCollected, totalEthTarget, "Total ETH collected should equal the target");
//         assertEq(user2FinalBalance, user2InitialBalance - remainingEth, "User2 should be refunded the excess ETH");
//         assertEq(
//             uint256(finalInfo.currentPhase),
//             uint256(KannonV1.LaunchPhase.IntermediatePresale),
//             "Phase should transition to IntermediatePresale"
//         );

//         console.log("Test passed: Participation exceeding available tokens handled correctly");
//     }

//     function testInitialPresaleSyncETHAndTokens() public {
//         // Create token and start presale
//         address tokenAddress = createTokenAndStartPresale();

//         // Get initial launch info
//         KannonV1.LaunchInfo memory initialInfo = kannonV1.getLaunchInfo(tokenAddress);
//         uint256 totalEthTarget = initialInfo.ethTarget;
//         uint256 initialPresaleDistributable = initialInfo.distributableSupply / 3;

//         // Prepare multiple users and ETH amounts
//         address[] memory users = new address[](5);
//         uint256[] memory ethAmounts = new uint256[](5);
//         for (uint256 i = 0; i < 5; i++) {
//             users[i] = makeAddr(string(abi.encodePacked("user", i + 1)));
//             ethAmounts[i] = totalEthTarget / (10 - i); // Varying ETH amounts
//             vm.deal(users[i], ethAmounts[i]);
//         }

//         // Participate in presale multiple times and check sync after each participation
//         for (uint256 i = 0; i < 5; i++) {
//             vm.prank(users[i]);
//             kannonV1.participateInPresale{value: ethAmounts[i]}(tokenAddress);

//             // Check sync after each participation
//             KannonV1.LaunchInfo memory currentInfo = kannonV1.getLaunchInfo(tokenAddress);
//             uint256 expectedTokens = currentInfo.ethCollected * initialPresaleDistributable / totalEthTarget;

//             console.log("Participation", i + 1);
//             console.log("ETH collected:", currentInfo.ethCollected);
//             console.log("Total presold tokens:", currentInfo.totalPresoldTokens);
//             console.log("Expected tokens:", expectedTokens);

//             assertApproxEqAbs(
//                 currentInfo.totalPresoldTokens,
//                 expectedTokens,
//                 1e6, // Allow for a small difference due to rounding
//                 "Total presold tokens should match expected tokens based on ETH collected"
//             );

//             // Check if we're still in the initial presale phase
//             if (uint256(currentInfo.currentPhase) != uint256(KannonV1.LaunchPhase.InitialPresale)) {
//                 console.log("Initial presale phase ended after participation", i + 1);
//                 break;
//             }
//         }

//         // Final check after all participations
//         KannonV1.LaunchInfo memory finalInfo = kannonV1.getLaunchInfo(tokenAddress);
//         console.log("Final ETH collected:", finalInfo.ethCollected);
//         console.log("Final total presold tokens:", finalInfo.totalPresoldTokens);
//         console.log("Final expected tokens:", finalInfo.ethCollected * initialPresaleDistributable / totalEthTarget);

//         assertApproxEqAbs(
//             finalInfo.totalPresoldTokens,
//             finalInfo.ethCollected * initialPresaleDistributable / totalEthTarget,
//             1e6, // Allow for a small difference due to rounding
//             "Final total presold tokens should match expected tokens based on total ETH collected"
//         );
//     }
// }
