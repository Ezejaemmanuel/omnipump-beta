// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.25;

// import {Test, console} from "forge-std/Test.sol";
// import {MainEngine} from "../../src/mainEngine.sol";
// import {DeployMainEngine} from "../../script/deployMainEngine.s.sol";
// import {CustomToken} from "../../src/customToken.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
// import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
// import {IQuoterV2} from "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";
// import {LiquidityAmounts} from "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
// import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
// import {FullMath} from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
// import {FixedPoint96} from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

// contract MainEngineSwapTest is Test {
//     MainEngine public mainEngine;
//     address public deployer;
//     address public user;
//     address public TOKEN_ADDRESS;
//     uint24 public constant FEE = 3000;
//     uint256 public constant SWAP_AMOUNT = 1 ether;
//     uint256 constant INITIAL_TOKEN_AMOUNT = 1000000000 ether; // 100,000 tokens
//     uint256 constant ETH_AMOUNT = 100000000 ether;
//     IQuoterV2 public quoterV2;
//     address public WETH9;

//     function setUp() public {
//         //console.log("=== setUp: Initializing test environment ===");

//         // vm.createSelectFork(sepoliaRpcUrl);
//         //console.log("setUp: Forked Sepolia at block:", block.number);

//         deployer = makeAddr("deployer");
//         user = makeAddr("user");
//         //console.log("setUp: Created deployer address:", deployer);
//         //console.log("setUp: Created user address:", user);

//         vm.deal(deployer, 10000000000000000 ether);
//         vm.deal(user, 100000000000000000000 ether);
//         //console.log("setUp: Funded deployer with 10,000,000,000,000,000 ETH");
//         //console.log("setUp: Funded user with 100,000,000,000,000,000,000 ETH");

//         DeployMainEngine deployScript = new DeployMainEngine();
//         //console.log("setUp: Created DeployMainEngine instance at:", address(deployScript));

//         (mainEngine,) = deployScript.run();

//         //console.log("setUp: MainEngine deployed at:", address(mainEngine));
//         //console.log("setUp: MainEngine factory address:", address(mainEngine.factory()));
//         //console.log("setUp: MainEngine nonfungiblePositionManager address:", address(mainEngine.nonfungiblePositionManager()));
//         //console.log("setUp: MainEngine swapRouter address:", address(mainEngine.swapRouter02()));
//         //console.log("setUp: MainEngine WETH9 address:", mainEngine.WETH9());
//         WETH9 = mainEngine.WETH9();

//         quoterV2 = mainEngine.quoterV2();
//         //console.log("setUp: Quoter address:", address(quoterV2));

//         //console.log("=== setUp: Test environment initialized ===");
//     }

//     function calculateDynamicTickRange(uint256 amount0, uint256 amount1, uint24 fee)
//         public
//         view
//         returns (int24 tickLower, int24 tickUpper)
//     {
//         //console.log("Function called with parameters:");
//         //console.log("amount0:", amount0);
//         //console.log("amount1:", amount1);
//         //console.log("fee:", fee);

//         require(amount0 > 0 && amount1 > 0, "Amounts must be greater than 0");
//         //console.log("Amounts validation passed");

//         // uint256 price = (amount1 * (10 ** 18)) / amount0;
//         // //console.log("Calculated price:", price);

//         // int24 currentTick = TickMath.getTickAtSqrtRatio(TickMath.getSqrtRatioAtTick(int24(price)));
//         uint256 price = (amount1 * (10 ** 18)) / amount0;
//         //console.log("Calculated price:", price);

//         // Convert price to sqrtPriceX96 format
//         uint160 sqrtPriceX96 = uint160(FullMath.mulDiv(FixedPoint96.Q96, FixedPoint96.Q96, price));

//         // Get the tick from sqrtPriceX96
//         int24 currentTick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
//         //console.log("Current tick:");
//         console.logInt(int256(currentTick));

//         int24 tickSpacing;
//         if (fee == 500) {
//             tickSpacing = 10;
//         } else if (fee == 3000) {
//             tickSpacing = 60;
//         } else {
//             tickSpacing = 200;
//         }
//         //console.log("Tick spacing:");
//         console.logInt(int256(tickSpacing));

//         int24 rangeSize = 100 * tickSpacing;
//         //console.log("Range size:");
//         console.logInt(int256(rangeSize));

//         tickLower = ((currentTick - rangeSize) / tickSpacing) * tickSpacing;
//         tickUpper = ((currentTick + rangeSize) / tickSpacing) * tickSpacing;
//         //console.log("Initial tickLower:");
//         console.logInt(int256(tickLower));
//         //console.log("Initial tickUpper:");
//         console.logInt(int256(tickUpper));

//         uint256 ratio = (amount0 * 100) / (amount0 + amount1);
//         //console.log("Calculated ratio:", ratio);

//         if (ratio > 60) {
//             //console.log("Ratio > 60, adjusting tickLower");
//             tickLower = ((currentTick - rangeSize * 3 / 2) / tickSpacing) * tickSpacing;
//             //console.log("New tickLower:");
//             console.logInt(int256(tickLower));
//         } else if (ratio < 40) {
//             //console.log("Ratio < 40, adjusting tickUpper");
//             tickUpper = ((currentTick + rangeSize * 3 / 2) / tickSpacing) * tickSpacing;
//             //console.log("New tickUpper:");
//             console.logInt(int256(tickUpper));
//         } else {
//             //console.log("Ratio between 40 and 60, no adjustment needed");
//         }

//         // Using if statements instead of Math.max and Math.min
//         if (tickLower < TickMath.MIN_TICK) {
//             tickLower = TickMath.MIN_TICK;
//         }
//         if (tickUpper > TickMath.MAX_TICK) {
//             tickUpper = TickMath.MAX_TICK;
//         }
//         //console.log("Final tickLower after MIN_TICK check:");
//         console.logInt(int256(tickLower));

//         //console.log("Final tickUpper after MAX_TICK check:");
//         console.logInt(int256(tickUpper));
//         // //console.log("Returning tickLower:", tickLower);
//         // //console.log("Returning tickUpper:", tickUpper);
//         return (tickLower, tickUpper);
//     }

//     function createTokensAndAddLiquidity() internal returns (address) {
//         //console.log("=== createTokensAndAddLiquidity: Creating token and adding liquidity ===");

//         vm.startPrank(deployer);

//         address token = createToken("Test Token", "TST");
//         //console.log("createTokensAndAddLiquidity: Token created at:", token);

//         vm.stopPrank();

//         uint256 tokenBalance = IERC20(token).balanceOf(address(mainEngine));
//         //console.log("createTokensAndAddLiquidity: MainEngine token balance:", tokenBalance);

//         //console.log("=== createTokensAndAddLiquidity: Token created and liquidity added ===");
//         return token;
//     }

//     function nearestUsableTick(int24 tick, int24 tickSpacing) public pure returns (int24) {
//         require(tickSpacing > 0, "TICK_SPACING");
//         require(tick >= TickMath.MIN_TICK && tick <= TickMath.MAX_TICK, "TICK_BOUND");

//         int24 rounded = tick / tickSpacing * tickSpacing;
//         if (tick < 0 && tick % tickSpacing != 0) rounded -= tickSpacing;
//         return rounded;
//     }

//     function createToken(string memory name, string memory symbol) internal returns (address) {
//         uint256 lockedLiquidityPercentage = 50; // 50%
//         string memory description = "A test token";
//         string memory imageUrl = "https://example.com/image.png";
//         string memory twitter = "https://example.com/image.png";
//         string memory telegram = "https://example.com/image.png";
//         string memory website = "https://example.com/image.png";
//         uint256 initialSupply = INITIAL_TOKEN_AMOUNT;

//         address tokenCreator = msg.sender;

//         address tokenAddr = mainEngine.createTokenAndAddLiquidity{value: ETH_AMOUNT}(
//             tokenCreator,
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

//         assertTrue(tokenAddr != address(0), "Token creation failed");

//         (, bool initialLiquidityAdded,,,,, address pool,) = mainEngine.tokenInfo(tokenAddr);
//         assertTrue(initialLiquidityAdded, "Initial liquidity not added");
//         assertTrue(pool != address(0), "Pool not created");

//         return tokenAddr;
//     }

//     function testSwapExactETHForTokensAndBack() public {
//         TOKEN_ADDRESS = createTokensAndAddLiquidity();

//         vm.startPrank(user);

//         uint256 initialETHBalance = user.balance;
//         uint256 initialWETHBalance = IERC20(mainEngine.WETH9()).balanceOf(user);
//         uint256 initialMainEngineWETHBalance = IERC20(mainEngine.WETH9()).balanceOf(address(mainEngine));
//         uint256 initialPoolWETHBalance = IERC20(mainEngine.WETH9()).balanceOf(mainEngine.getPoolAddress(TOKEN_ADDRESS));
//         uint256 initialGas = gasleft();

//         IERC20(mainEngine.WETH9()).approve(address(mainEngine), SWAP_AMOUNT);

//         // Log initial state
//         logPoolState("Initial State", true);

//         uint256 initialTokenBalance = mainEngine.getTokenBalance(TOKEN_ADDRESS, user);

//         // Store initial values for comparison
//         (uint160 sqrtPriceX96, int24 initialTick) = mainEngine.getPoolSlot0(TOKEN_ADDRESS);
//         uint256 initialPrice = mainEngine.calculatePriceFromSqrtPriceX96(sqrtPriceX96, TOKEN_ADDRESS);
//         uint128 initialLiquidity = mainEngine.getPoolLiquidity(TOKEN_ADDRESS);
//         address pool = mainEngine.getPoolAddress(TOKEN_ADDRESS);
//         uint256 initialToken0Balance = IERC20(mainEngine.WETH9()).balanceOf(pool);
//         uint256 initialToken1Balance = IERC20(TOKEN_ADDRESS).balanceOf(pool);

//         // Swap ETH for Tokens
//         uint256 tokensReceived = mainEngine.swapExactETHForTokens{value: SWAP_AMOUNT}(TOKEN_ADDRESS);

//         // Log state after first swap
//         logPoolState("After ETH to Token Swap", false);
//         logPoolStateChanges(
//             initialPrice,
//             initialTick,
//             initialLiquidity,
//             initialToken0Balance,
//             initialToken1Balance,
//             initialETHBalance,
//             initialTokenBalance
//         );

//         console.log("Tokens received by user:", tokensReceived);

//         uint256 postSwapETHBalance = user.balance;
//         uint256 postSwapTokenBalance = mainEngine.getTokenBalance(TOKEN_ADDRESS, address(mainEngine));
//         uint256 postSwapWETHBalance = IERC20(mainEngine.WETH9()).balanceOf(user);
//         uint256 postSwapMainEngineWETHBalance = IERC20(mainEngine.WETH9()).balanceOf(address(mainEngine));
//         uint256 postSwapPoolWETHBalance = IERC20(mainEngine.WETH9()).balanceOf(pool);
//         uint256 gasUsedFirstSwap = initialGas - gasleft();

//         assertLt(postSwapETHBalance, initialETHBalance, "ETH balance should decrease");
//         assertGt(postSwapTokenBalance, initialTokenBalance, "Token balance should increase");

//         // Log additional tracked changes
//         logAdditionalChanges(
//             "First Swap",
//             initialWETHBalance,
//             postSwapWETHBalance,
//             initialMainEngineWETHBalance,
//             postSwapMainEngineWETHBalance,
//             initialPoolWETHBalance,
//             postSwapPoolWETHBalance,
//             gasUsedFirstSwap
//         );

//         // IERC20(TOKEN_ADDRESS).approve(address(mainEngine), 10000 ether);

//         // Store values before second swap
//         int24 preTick;
//         (sqrtPriceX96, preTick) = mainEngine.getPoolSlot0(TOKEN_ADDRESS);
//         uint256 prePrice = mainEngine.calculatePriceFromSqrtPriceX96(sqrtPriceX96, TOKEN_ADDRESS);
//         uint128 preLiquidity = mainEngine.getPoolLiquidity(TOKEN_ADDRESS);
//         uint256 preToken0Balance = IERC20(mainEngine.WETH9()).balanceOf(pool);
//         uint256 preToken1Balance = IERC20(TOKEN_ADDRESS).balanceOf(pool);
//         uint256 preUserETHBalance = user.balance;
//         uint256 preUserTokenBalance = mainEngine.getTokenBalance(TOKEN_ADDRESS, user);
//         uint256 preUserWETHBalance = IERC20(mainEngine.WETH9()).balanceOf(user);
//         uint256 preMainEngineWETHBalance = IERC20(mainEngine.WETH9()).balanceOf(address(mainEngine));
//         uint256 prePoolWETHBalance = IERC20(mainEngine.WETH9()).balanceOf(pool);
//         uint256 preGas = gasleft();

//         IERC20(TOKEN_ADDRESS).approve(address(mainEngine), 1 ether);

//         // Swap Tokens back to ETH
//         uint256 ethReceived = mainEngine.swapExactTokensForETH(TOKEN_ADDRESS, 1 ether);

//         // Log state after second swap
//         logPoolState("After Token to ETH Swap", false);
//         logPoolStateChanges(
//             prePrice, preTick, preLiquidity, preToken0Balance, preToken1Balance, preUserETHBalance, preUserTokenBalance
//         );

//         console.log("ETH received by user :", ethReceived);

//         uint256 finalETHBalance = user.balance;
//         uint256 finalTokenBalance = mainEngine.getTokenBalance(TOKEN_ADDRESS, user);
//         uint256 finalWETHBalance = IERC20(mainEngine.WETH9()).balanceOf(user);
//         uint256 finalMainEngineWETHBalance = IERC20(mainEngine.WETH9()).balanceOf(address(mainEngine));
//         uint256 finalPoolWETHBalance = IERC20(mainEngine.WETH9()).balanceOf(pool);
//         uint256 gasUsedSecondSwap = preGas - gasleft();

//         assertGt(finalETHBalance, postSwapETHBalance, "ETH balance should increase");
//         assertLt(finalTokenBalance, postSwapTokenBalance, "Token balance should decrease");
//         assertEq(finalTokenBalance, 0, "All tokens should be swapped back");
//         assertEq(
//             finalETHBalance, postSwapETHBalance + ethReceived, "ETH balance should increase by the amount received"
//         );
//         assertApproxEqRel(ethReceived, SWAP_AMOUNT, 1e16, "Received ETH should be close to initial swap amount");

//         // Log additional tracked changes for second swap
//         logAdditionalChanges(
//             "Second Swap",
//             preUserWETHBalance,
//             finalWETHBalance,
//             preMainEngineWETHBalance,
//             finalMainEngineWETHBalance,
//             prePoolWETHBalance,
//             finalPoolWETHBalance,
//             gasUsedSecondSwap
//         );

//         vm.stopPrank();
//     }

//     function logPoolState(string memory state, bool isInitial) internal view {
//         console.log("--------------------");
//         console.log(state);
//         console.log("--------------------");
//         address pool = mainEngine.getPoolAddress(TOKEN_ADDRESS);
//         (uint160 sqrtPriceX96, int24 tick) = mainEngine.getPoolSlot0(TOKEN_ADDRESS);
//         uint256 price = mainEngine.calculatePriceFromSqrtPriceX96(sqrtPriceX96, TOKEN_ADDRESS);
//         uint128 liquidity = mainEngine.getPoolLiquidity(TOKEN_ADDRESS);
//         console.log("Format: [Current Value] (Previous Value)");
//         console.log("Current Price: [%s] %s", price, isInitial ? "(Initial)" : "");
//         console.log("Current Tick: [%s] %s", uint256(uint24(tick)), isInitial ? "(Initial)" : "");
//         console.log("Pool Liquidity: [%s] %s", liquidity, isInitial ? "(Initial)" : "");
//         uint256 token0Balance = IERC20(mainEngine.WETH9()).balanceOf(pool);
//         uint256 token1Balance = IERC20(TOKEN_ADDRESS).balanceOf(pool);
//         console.log("WETH Balance in Pool: [%s] %s", token0Balance, isInitial ? "(Initial)" : "");
//         console.log("Token Balance in Pool: [%s] %s", token1Balance, isInitial ? "(Initial)" : "");
//         // Log user balances
//         uint256 userETHBalance = user.balance;
//         uint256 userTokenBalance = mainEngine.getTokenBalance(TOKEN_ADDRESS, user);
//         console.log("User ETH Balance: [%s] %s", userETHBalance, isInitial ? "(Initial)" : "");
//         console.log("User Token Balance: [%s] %s", userTokenBalance, isInitial ? "(Initial)" : "");
//     }

//     function logPoolStateChanges(
//         uint256 prevPrice,
//         int24 prevTick,
//         uint128 prevLiquidity,
//         uint256 prevToken0Balance,
//         uint256 prevToken1Balance,
//         uint256 prevUserETHBalance,
//         uint256 prevUserTokenBalance
//     ) internal view {
//         console.log("--------------------");
//         console.log("Pool State Changes");
//         console.log("--------------------");
//         address pool = mainEngine.getPoolAddress(TOKEN_ADDRESS);
//         (uint160 sqrtPriceX96, int24 currentTick) = mainEngine.getPoolSlot0(TOKEN_ADDRESS);
//         uint256 currentPrice = mainEngine.calculatePriceFromSqrtPriceX96(sqrtPriceX96, TOKEN_ADDRESS);
//         uint128 currentLiquidity = mainEngine.getPoolLiquidity(TOKEN_ADDRESS);
//         console.log("Format: [Current Value] (Change)");
//         if (currentPrice >= prevPrice) {
//             console.log("Price: [%s] (+%s)", currentPrice, currentPrice - prevPrice);
//         } else {
//             console.log("Price: [%s] (-%s)", currentPrice, prevPrice - currentPrice);
//         }
//         uint256 currentTickUint = uint256(uint24(currentTick));
//         uint256 prevTickUint = uint256(uint24(prevTick));
//         if (currentTickUint >= prevTickUint) {
//             console.log("Tick: [%s] (+%s)", currentTickUint, currentTickUint - prevTickUint);
//         } else {
//             console.log("Tick: [%s] (-%s)", currentTickUint, prevTickUint - currentTickUint);
//         }
//         if (currentLiquidity >= prevLiquidity) {
//             console.log("Pool Liquidity: [%s] (+%s)", currentLiquidity, currentLiquidity - prevLiquidity);
//         } else {
//             console.log("Pool Liquidity: [%s] (-%s)", currentLiquidity, prevLiquidity - currentLiquidity);
//         }
//         uint256 currentToken0Balance = IERC20(mainEngine.WETH9()).balanceOf(pool);
//         uint256 currentToken1Balance = IERC20(TOKEN_ADDRESS).balanceOf(pool);
//         if (currentToken0Balance >= prevToken0Balance) {
//             console.log(
//                 "WETH Balance in Pool: [%s] (+%s)", currentToken0Balance, currentToken0Balance - prevToken0Balance
//             );
//         } else {
//             console.log(
//                 "WETH Balance in Pool: [%s] (-%s)", currentToken0Balance, prevToken0Balance - currentToken0Balance
//             );
//         }
//         if (currentToken1Balance >= prevToken1Balance) {
//             console.log(
//                 "Token Balance in Pool: [%s] (+%s)", currentToken1Balance, currentToken1Balance - prevToken1Balance
//             );
//         } else {
//             console.log(
//                 "Token Balance in Pool: [%s] (-%s)", currentToken1Balance, prevToken1Balance - currentToken1Balance
//             );
//         }
//         // Log user balance changes
//         uint256 currentUserETHBalance = user.balance;
//         uint256 currentUserTokenBalance = mainEngine.getTokenBalance(TOKEN_ADDRESS, user);
//         if (currentUserETHBalance >= prevUserETHBalance) {
//             console.log(
//                 "User ETH Balance: [%s] (+%s)", currentUserETHBalance, currentUserETHBalance - prevUserETHBalance
//             );
//         } else {
//             console.log(
//                 "User ETH Balance: [%s] (-%s)", currentUserETHBalance, prevUserETHBalance - currentUserETHBalance
//             );
//         }
//         if (currentUserTokenBalance >= prevUserTokenBalance) {
//             console.log(
//                 "User Token Balance: [%s] (+%s)",
//                 currentUserTokenBalance,
//                 currentUserTokenBalance - prevUserTokenBalance
//             );
//         } else {
//             console.log(
//                 "User Token Balance: [%s] (-%s)",
//                 currentUserTokenBalance,
//                 prevUserTokenBalance - currentUserTokenBalance
//             );
//         }
//     }

//     function logAdditionalChanges(
//         string memory swapType,
//         uint256 preUserWETHBalance,
//         uint256 postUserWETHBalance,
//         uint256 preMainEngineWETHBalance,
//         uint256 postMainEngineWETHBalance,
//         uint256 prePoolWETHBalance,
//         uint256 postPoolWETHBalance,
//         uint256 gasUsed
//     ) internal view {
//         console.log("--------------------");
//         console.log("Additional Changes for %s", swapType);
//         console.log("--------------------");

//         console.log("Format: [Current Value] (Change)");

//         if (postUserWETHBalance >= preUserWETHBalance) {
//             console.log("User WETH Balance: [%s] (+%s)", postUserWETHBalance, postUserWETHBalance - preUserWETHBalance);
//         } else {
//             console.log("User WETH Balance: [%s] (-%s)", postUserWETHBalance, preUserWETHBalance - postUserWETHBalance);
//         }

//         if (postMainEngineWETHBalance >= preMainEngineWETHBalance) {
//             console.log(
//                 "MainEngine WETH Balance: [%s] (+%s)",
//                 postMainEngineWETHBalance,
//                 postMainEngineWETHBalance - preMainEngineWETHBalance
//             );
//         } else {
//             console.log(
//                 "MainEngine WETH Balance: [%s] (-%s)",
//                 postMainEngineWETHBalance,
//                 preMainEngineWETHBalance - postMainEngineWETHBalance
//             );
//         }

//         if (postPoolWETHBalance >= prePoolWETHBalance) {
//             console.log("Pool WETH Balance: [%s] (+%s)", postPoolWETHBalance, postPoolWETHBalance - prePoolWETHBalance);
//         } else {
//             console.log("Pool WETH Balance: [%s] (-%s)", postPoolWETHBalance, prePoolWETHBalance - postPoolWETHBalance);
//         }

//         console.log("Gas Used: [%s]", gasUsed);
//     }
// }
