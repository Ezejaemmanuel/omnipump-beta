// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import {InvariantTest} from "forge-std/InvariantTest.sol";
// import {Test} from "forge-std/Test.sol";
// import {KannonV1} from "../../src/solving-overflow-and-underflow-error.sol";
// import {CustomToken} from "../../src/customToken.sol";
// import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
// import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
// import {DeployKannonV1} from "../../script/deployKannonV1.s.sol";

// contract KannonV1InvariantTest2 is InvariantTest, Test {
//     KannonV1 public KannonV1;
//     address public user;
//     address public deployer;

//     // Define constants for bounds
//     uint256 constant MIN_ETH_AMOUNT = 1e12;      // 0.000001 ETH in wei
//     uint256 constant MAX_ETH_AMOUNT = 1e27;      // 1 billion ETH in wei
//     uint256 constant MIN_INITIAL_SUPPLY = 1e18;  // 1 token (assuming 18 decimals)
//     uint256 constant MAX_INITIAL_SUPPLY = 1e27;  // 1e9 tokens (1 billion)

//     function setUp() public {
//         deployer = makeAddr("deployer");
//         user = makeAddr("user");

//         // Fund the user with a large amount of ETH
//         vm.deal(user, 100000000000 ether);

//         // Deploy the KannonV1 contract
//         DeployKannonV1 deployScript = new DeployKannonV1();
//         (KannonV1,) = deployScript.run();
//     }

//     /**
//      * @dev Invariant test that repeatedly calls `createTokenAndAddLiquidity` with random `initialSupply` and `ethAmount`.
//      * It asserts that after each operation, critical invariants hold true.
//      */
//     function invariant_createTokenAndAddLiquidity(
//         uint256 initialSupply,
//         uint256 ethAmount
//     ) public {
//         // Bound the inputs to the specified ranges
//         initialSupply = bound(initialSupply, MIN_INITIAL_SUPPLY, MAX_INITIAL_SUPPLY);
//         ethAmount = bound(ethAmount, MIN_ETH_AMOUNT, MAX_ETH_AMOUNT);

//         // Ensure the user has enough ETH
//         vm.assume(ethAmount <= address(user).balance);

//         // Start impersonating the user
//         vm.startPrank(user);

//         // Define token parameters
//         string memory name = "Invariant Test Token";
//         string memory symbol = "ITT";
//         string memory description = "A test token for invariant testing";
//         string memory imageUrl = "https://example.com/image.png";
//         string memory twitter = "@invarianttest";
//         string memory telegram = "@invarianttest";
//         string memory website = "https://invarianttest.com";
//         uint256 lockedLiquidityPercentage = uint256(bound(lockedLiquidityPercentage(), 1, 100)); // Ensure 1-100%

//         // Call `createTokenAndAddLiquidity`
//         address tokenAddress = KannonV1.createTokenAndAddLiquidity{value: ethAmount}(
//             user,
//             name,
//             symbol,
//             description,
//             imageUrl,
//             twitter,
//             telegram,
//             website,
//             initialSupply,
//             lockedLiquidityPercentage
//         );

//         // Stop impersonating the user
//         vm.stopPrank();

//         // Fetch token information
//         (
//             address creator,
//             bool initialLiquidityAdded,
//             uint256 positionId,
//             uint256 storedLockedLiquidityPercentage,
//             uint256 withdrawableLiquidity,
//             uint256 creationTime,
//             address poolAddress,
//             uint128 liquidity
//         ) = KannonV1.tokenInfo(tokenAddress);

//         // Fetch the token contract
//         CustomToken token = CustomToken(tokenAddress);

//         // **Invariant 1:** Token metadata should be correctly set
//         assertEq(token.name(), name, "Token name mismatch");
//         assertEq(token.symbol(), symbol, "Token symbol mismatch");
//         assertEq(token.totalSupply(), initialSupply, "Initial supply mismatch");

//         // **Invariant 2:** Creator should be the user
//         assertEq(creator, user, "Creator mismatch");

//         // **Invariant 3:** Initial liquidity should be added
//         assertTrue(initialLiquidityAdded, "Initial liquidity not added");

//         // **Invariant 4:** Position ID should be valid
//         assertGt(positionId, 0, "Invalid position ID");

//         // **Invariant 5:** Locked liquidity percentage should be within bounds
//         assertGe(storedLockedLiquidityPercentage, 1, "Locked liquidity percentage below 1");
//         assertLe(storedLockedLiquidityPercentage, 100, "Locked liquidity percentage above 100");

//         // **Invariant 6:** Withdrawable liquidity should not exceed total liquidity
//         assertLe(withdrawableLiquidity, uint256(liquidity), "Withdrawable liquidity exceeds total liquidity");

//         // **Invariant 7:** Pool address should be valid
//         assertTrue(poolAddress != address(0), "Pool not created");

//         // **Invariant 8:** Liquidity should be greater than zero
//         assertGt(liquidity, 0, "No liquidity added");

//         // **Invariant 9:** Verify the Uniswap pool's fee
//         IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
//         uint24 expectedFee = 3000; // 0.3%
//         assertEq(pool.fee(), expectedFee, "Pool fee mismatch");

//         // **Invariant 10:** Verify position details
//         INonfungiblePositionManager positionManager = KannonV1.nonfungiblePositionManager();
//         (
//             ,
//             ,
//             address token0,
//             address token1,
//             uint24 positionFee,
//             int24 positionTickLower,
//             int24 positionTickUpper,
//             uint128 positionLiquidity,
//             ,
//             ,
//             ,
//         ) = positionManager.positions(positionId);

//         // Ensure tokens are sorted correctly
//         assertTrue(token0 < token1, "Tokens not sorted in pool");

//         // Ensure one of the tokens is the created token
//         assertTrue(token0 == tokenAddress || token1 == tokenAddress, "Token not part of position");

//         // Ensure pool fee matches
//         assertEq(positionFee, expectedFee, "Position fee mismatch");

//         // Ensure liquidity in the position is greater than zero
//         assertGt(positionLiquidity, 0, "No liquidity in position");
//     }

//     /**
//      * @dev Helper function to generate a random locked liquidity percentage between 1 and 100.
//      */
//     function lockedLiquidityPercentage() internal view returns (uint256) {
//         return uint256(keccak256(abi.encodePacked(block.timestamp, block.number))) % 100 + 1;
//     }
// }
