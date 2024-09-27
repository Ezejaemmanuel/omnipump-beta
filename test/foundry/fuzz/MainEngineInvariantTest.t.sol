// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import {InvariantTest} from "forge-std/InvariantTest.sol";
// import {Test} from "forge-std/Test.sol";
// import {KannonV1} from "../../../src/solving-overflow-and-underflow-error.sol";
// import {KannonV1Handler} from "./KannonV1Handler.t.sol";
// import {DeployKannonV1} from "../../../script/deployKannonV1.s.sol";
// import {CustomToken} from "../../../src/customToken.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
// import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

// contract KannonV1InvariantTest is InvariantTest, Test {
//     KannonV1 public KannonV1;
//     KannonV1Handler public handler;
//     address public user;

//     // Define constants for bounds (optional, since handler manages it)
//     uint256 constant LIQUIDITY_LOCK_PERIOD = 3 days;

//     function setUp() public {
//         // Deploy KannonV1
//         DeployKannonV1 deployScript = new DeployKannonV1();
//         (KannonV1,) = deployScript.run();

//         // Create user address
//         user = makeAddr("user");

//         // Instantiate handler
//         handler = new KannonV1Handler(KannonV1, user);

//         // Set the target contract for invariant testing
//         targetContract(address(handler));
//     }

//     /**
//      * @dev Invariant test that ensures the integrity of createTokenAndAddLiquidity across random inputs.
//      */
//     function invariant_tokenCreationAndLiquidity() public {
//         // Perform multiple token creations with randomized parameters
//         // You can adjust the loop count as needed for rigorous testing
//         for (uint256 i = 0; i < 10; i++) {
//             handler.createTokenAndAddLiquidity();
//         }

//         // Retrieve all created tokens
//         address[] memory createdTokens = handler.getCreatedTokens();

//         // Iterate through each created token and assert invariants
//         for (uint256 i = 0; i < createdTokens.length; i++) {
//             address tokenAddress = createdTokens[i];
//             require(tokenAddress != address(0), "Invalid token address");

//             // Fetch token information from KannonV1
//             (
//                 address creator,
//                 bool initialLiquidityAdded,
//                 uint256 positionId,
//                 uint256 lockedLiquidityPercentage,
//                 uint256 withdrawableLiquidity,
//                 uint256 creationTime,
//                 address poolAddress,
//                 uint128 liquidity
//             ) = KannonV1.tokenInfo(tokenAddress);

//             // **Invariant 1:** Creator should be the user
//             assertEq(creator, user, "Creator mismatch");

//             // **Invariant 2:** Initial liquidity should be added
//             assertTrue(initialLiquidityAdded, "Initial liquidity not added");

//             // **Invariant 3:** Position ID should be valid
//             assertGt(positionId, 0, "Invalid position ID");

//             // **Invariant 4:** Locked liquidity percentage should be within bounds
//             assertGe(lockedLiquidityPercentage, 1, "Locked liquidity percentage below 1");
//             assertLe(lockedLiquidityPercentage, 100, "Locked liquidity percentage above 100");

//             // **Invariant 5:** Withdrawable liquidity should not exceed total liquidity
//             assertLe(withdrawableLiquidity, uint256(liquidity), "Withdrawable liquidity exceeds total liquidity");

//             // **Invariant 6:** Pool address should be valid
//             assertTrue(poolAddress != address(0), "Pool not created");

//             // **Invariant 7:** Liquidity should be greater than zero
//             assertGt(liquidity, 0, "No liquidity added");

//             // **Invariant 8:** Token balance of KannonV1 should be greater than zero
//             assertGt(IERC20(tokenAddress).balanceOf(address(KannonV1)), 0, "KannonV1 token balance is zero");

//             // **Invariant 9:** Total supply of the token should be greater than zero
//             assertGt(IERC20(tokenAddress).totalSupply(), 0, "Total supply is zero");

//             // **Invariant 10:** Verify Uniswap V3 Pool's fee
//             IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
//             uint24 expectedFee = 3000; // 0.3%
//             assertEq(pool.fee(), expectedFee, "Pool fee mismatch");

//             // **Invariant 11:** Verify position details
//             INonfungiblePositionManager positionManager = KannonV1.nonfungiblePositionManager();
//             (
//                 ,
//                 ,
//                 address token0,
//                 address token1,
//                 uint24 positionFee,
//                 int24 positionTickLower,
//                 int24 positionTickUpper,
//                 uint128 positionLiquidity,
//                 ,
//                 ,
//                 ,
//             ) = positionManager.positions(positionId);

//             // Ensure tokens are sorted correctly
//             assertTrue(token0 < token1, "Tokens not sorted in pool");

//             // Ensure one of the tokens is the created token
//             assertTrue(token0 == tokenAddress || token1 == tokenAddress, "Token not part of position");

//             // Ensure pool fee matches
//             assertEq(positionFee, expectedFee, "Position fee mismatch");

//             // Ensure liquidity in the position is greater than zero
//             assertGt(positionLiquidity, 0, "No liquidity in position");

//             // **Invariant 12:** Ensure liquidity lock period is respected
//             uint256 lockEndTime = creationTime + LIQUIDITY_LOCK_PERIOD;
//             if (block.timestamp < lockEndTime) {
//                 // Liquidity should still be locked
//                 // Add any specific checks related to liquidity lock if applicable
//             }
//         }
//     }
// }
