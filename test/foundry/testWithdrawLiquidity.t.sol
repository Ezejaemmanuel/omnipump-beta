// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import {Test, console} from "forge-std/Test.sol";
// import {KannonV1} from "../../src/KannonV1.sol";
// import {DeployKannonV1} from "../../script/deployKannonV1.s.sol";
// import {CustomToken} from "../../src/customToken.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
// import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
// import {IQuoterV2} from "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";
// import {LiquidityAmounts} from "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
// import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
// import {FullMath} from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
// import {FixedPoint96} from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

// contract KannonV1SwapTest is Test {
//     KannonV1 public KannonV1;
//     address public deployer;
//     address public user;
//     address public TOKEN_ADDRESS;
//     uint24 public constant FEE = 3000;
//     uint256 public constant SWAP_AMOUNT = 0.001 ether;
//     uint256 constant INITIAL_TOKEN_AMOUNT = 1000 ether; // 100,000 tokens
//     uint256 constant ETH_AMOUNT = 1000 ether;
//     IQuoterV2 public quoterV2;
//     address public WETH9;
//     uint256 public constant NUM_SWAPS = 5;

//     function setUp() public {
//         deployer = makeAddr("deployer");
//         user = makeAddr("user");

//         vm.deal(deployer, 1000000000000 ether);
//         vm.deal(user, 1000000000000 ether);

//         DeployKannonV1 deployScript = new DeployKannonV1();

//         (KannonV1,) = deployScript.run();

//         WETH9 = KannonV1.WETH9();

//         quoterV2 = KannonV1.quoterV2();
//     }

//     function createTokensAndAddLiquidity() internal returns (address) {
//         //console.log("=== createTokensAndAddLiquidity: Creating token and adding liquidity ===");

//         vm.startPrank(deployer);

//         address token = createToken("Test Token", "TST");
//         //console.log("createTokensAndAddLiquidity: Token created at:", token);

//         vm.stopPrank();

//         uint256 tokenBalance = IERC20(token).balanceOf(address(KannonV1));
//         //console.log("createTokensAndAddLiquidity: KannonV1 token balance:", tokenBalance);

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
//         uint24 fee = 3000; // 0.3%
//         string memory description = "A test token";
//         string memory imageUrl = "https://example.com/image.png";
//         string memory twitter = "https://example.com/image.png";
//         string memory telegram = "https://example.com/image.png";
//         string memory website = "https://example.com/image.png";
//         uint256 initialSupply = INITIAL_TOKEN_AMOUNT;

//         address tokenCreator = msg.sender;

//         address tokenAddr = KannonV1.createTokenAndAddLiquidity{value: ETH_AMOUNT}(
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

//         (, bool initialLiquidityAdded,,,,, address pool,) = KannonV1.tokenInfo(tokenAddr);
//         assertTrue(initialLiquidityAdded, "Initial liquidity not added");
//         assertTrue(pool != address(0), "Pool not created");

//         return tokenAddr;
//     }

//     function testCannotWithdrawBeforeLockPeriod() public {
//         TOKEN_ADDRESS = createTokensAndAddLiquidity();

//         vm.prank(deployer);
//         vm.expectRevert(KannonV1.WithdrawalTooEarly.selector);
//         KannonV1.withdrawLiquidity(TOKEN_ADDRESS, 1 ether);
//     }

//     function testOnlyTokenCreatorCanWithdrawLiquidity() public {
//         // Create a token and add liquidity
//         address tokenAddress = createTokensAndAddLiquidity();

//         // Wait for the lock period to end
//         vm.warp(block.timestamp + KannonV1.LIQUIDITY_LOCK_PERIOD() + 1);

//         // Try to withdraw liquidity as the token creator (should succeed)
//         vm.prank(user);
//         (,,,, uint256 withdrawableLiquidity,,,) = KannonV1.tokenInfo(TOKEN_ADDRESS);

//         uint256 withdrawAmount = withdrawableLiquidity / 2;
//         // KannonV1.withdrawLiquidity(tokenAddress, withdrawAmount);

//         // Try to withdraw liquidity as a different address (should fail)
//         address notCreator = address(0xdeadbeef);
//         vm.expectRevert(KannonV1.NotAuthorized.selector);
//         vm.prank(notCreator);

//         KannonV1.withdrawLiquidity(tokenAddress, withdrawAmount);
//     }

//     function testCannotWithdrawMoreThanAvailable() public {
//         TOKEN_ADDRESS = createTokensAndAddLiquidity();

//         vm.warp(block.timestamp + KannonV1.LIQUIDITY_LOCK_PERIOD() + 1);

//         (,,,, uint256 availableLiquidity,,,) = KannonV1.tokenInfo(TOKEN_ADDRESS);
//         vm.prank(deployer);
//         vm.expectRevert(KannonV1.InsufficientWithdrawableLiquidity.selector);
//         KannonV1.withdrawLiquidity(TOKEN_ADDRESS, availableLiquidity + 1);
//     }

//     function testWithdrawLiquidity() public {
//         TOKEN_ADDRESS = createTokensAndAddLiquidity();

//         performSwaps();

//         vm.warp(block.timestamp + KannonV1.LIQUIDITY_LOCK_PERIOD() + 1);

//         logPoolState("Initial State", true);

//         (uint160 sqrtPriceX96, int24 initialTick) = KannonV1.getPoolSlot0(TOKEN_ADDRESS);
//         uint256 initialPrice = KannonV1.calculatePriceFromSqrtPriceX96(sqrtPriceX96, TOKEN_ADDRESS);
//         uint128 initialLiquidity = KannonV1.getPoolLiquidity(TOKEN_ADDRESS);
//         address pool = KannonV1.getPoolAddress(TOKEN_ADDRESS);
//         uint256 initialToken0Balance = IERC20(KannonV1.WETH9()).balanceOf(pool);
//         uint256 initialToken1Balance = IERC20(TOKEN_ADDRESS).balanceOf(pool);
//         uint256 initialUserETHBalance = user.balance;
//         uint256 initialUserTokenBalance = KannonV1.getTokenBalance(TOKEN_ADDRESS, user);

//         (,,,, uint256 availableLiquidity,,,) = KannonV1.tokenInfo(TOKEN_ADDRESS);
//         uint256 withdrawAmount = availableLiquidity / 2;
//         vm.prank(deployer);
//         KannonV1.withdrawLiquidity(TOKEN_ADDRESS, withdrawAmount);

//         logPoolState("After Liquidity Withdrawal", false);
//         logPoolStateChanges(
//             initialPrice,
//             initialTick,
//             initialLiquidity,
//             initialToken0Balance,
//             initialToken1Balance,
//             initialUserETHBalance,
//             initialUserTokenBalance
//         );
//         (,,,, uint256 withdrawableLiquidity,,, uint128 liquidity) = KannonV1.tokenInfo(TOKEN_ADDRESS);

//         assertLt(withdrawableLiquidity, liquidity, "Withdrawable liquidity should decrease");
//         assertGe(
//             user.balance,
//             initialUserETHBalance,
//             "User's ETH balance should be greater than or equal to the initial balance"
//         );
//         // assertGt(user.balance, initialUserETHBalance, "User's ETH balance should increase");
//         // assertGt(
//         //     KannonV1.getTokenBalance(TOKEN_ADDRESS, user),
//         //     initialUserTokenBalance,
//         //     "User's token balance should increase"
//         // );
//     }

//     function performSwaps() internal {
//         vm.startPrank(user);
//         for (uint256 i = 0; i < NUM_SWAPS; i++) {
//             uint256 tokensReceived = KannonV1.swapExactETHForTokens{value: SWAP_AMOUNT}(TOKEN_ADDRESS);

//             IERC20(TOKEN_ADDRESS).approve(address(KannonV1), tokensReceived * 10);
//             uint256 ethReceived = KannonV1.swapExactTokensForETH(TOKEN_ADDRESS, tokensReceived);

//             logSwapDetails(i + 1, SWAP_AMOUNT, tokensReceived, ethReceived);
//         }
//         vm.stopPrank();
//     }

//     function logSwapDetails(uint256 swapNumber, uint256 ethIn, uint256 tokensReceived, uint256 ethOut) internal view {
//         console.log("--------------------");
//         console.log("Swap %s Details", swapNumber);
//         console.log("--------------------");
//         console.log("ETH in: %s", ethIn);
//         console.log("Tokens received: %s", tokensReceived);
//         console.log("ETH out: %s", ethOut);
//         console.log("Slippage: %s%%", ((ethIn - ethOut) * 10000 / ethIn) / 100);
//     }

//     function logPoolState(string memory state, bool isInitial) internal view {
//         console.log("--------------------");
//         console.log(state);
//         console.log("--------------------");

//         address poolLogAddr = KannonV1.getPoolAddress(TOKEN_ADDRESS);
//         (uint160 sqrtPriceX96, int24 tick) = KannonV1.getPoolSlot0(TOKEN_ADDRESS);
//         uint256 price = KannonV1.calculatePriceFromSqrtPriceX96(sqrtPriceX96, TOKEN_ADDRESS);
//         uint128 liquidityLog = KannonV1.getPoolLiquidity(TOKEN_ADDRESS);

//         console.log("Format: [Current Value] (Previous Value)");
//         console.log("Current Price: [%s] %s", price, isInitial ? "(Initial)" : "");
//         console.log("Current Tick: [%s] %s", uint256(uint24(tick)), isInitial ? "(Initial)" : "");
//         console.log("Pool Liquidity: [%s] %s", liquidityLog, isInitial ? "(Initial)" : "");

//         uint256 token0Balance = IERC20(KannonV1.WETH9()).balanceOf(poolLogAddr);
//         uint256 token1Balance = IERC20(TOKEN_ADDRESS).balanceOf(poolLogAddr);
//         console.log("WETH Balance in Pool: [%s] %s", token0Balance, isInitial ? "(Initial)" : "");
//         console.log("Token Balance in Pool: [%s] %s", token1Balance, isInitial ? "(Initial)" : "");

//         uint256 userETHBalance = user.balance;
//         uint256 userTokenBalance = KannonV1.getTokenBalance(TOKEN_ADDRESS, user);
//         console.log("User ETH Balance: [%s] %s", userETHBalance, isInitial ? "(Initial)" : "");
//         console.log("User Token Balance: [%s] %s", userTokenBalance, isInitial ? "(Initial)" : "");

//         (
//             address creator,
//             bool initialLiquidityAdded,
//             uint256 positionId,
//             uint256 lockedLiquidityPercentage,
//             uint256 withdrawableLiquidity,
//             uint256 creationTime,
//             address pool,
//             uint128 liquidity
//         ) = KannonV1.tokenInfo(TOKEN_ADDRESS);

//         console.log("TokenInfo:");
//         console.log(" Creator: %s", creator);
//         console.log(" Initial Liquidity Added: %s", initialLiquidityAdded);
//         console.log(" Position ID: %s", positionId);
//         console.log(" Locked Liquidity Percentage: %s", lockedLiquidityPercentage);
//         console.log(" Withdrawable Liquidity: %s", withdrawableLiquidity);
//         console.log(" Creation Time: %s", creationTime);
//         console.log(" Pool Address: %s", pool);
//         console.log(" Liquidity: %s", liquidity);
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

//         address poolLogAddrState = KannonV1.getPoolAddress(TOKEN_ADDRESS);
//         (uint160 sqrtPriceX96, int24 currentTick) = KannonV1.getPoolSlot0(TOKEN_ADDRESS);
//         uint256 currentPrice = KannonV1.calculatePriceFromSqrtPriceX96(sqrtPriceX96, TOKEN_ADDRESS);
//         uint128 currentLiquidity = KannonV1.getPoolLiquidity(TOKEN_ADDRESS);

//         console.log("Format: [Current Value] (Change)");
//         logChange("Price", currentPrice, prevPrice);
//         logChange("Tick", uint256(uint24(currentTick)), uint256(uint24(prevTick)));
//         logChange("Pool Liquidity", uint256(currentLiquidity), uint256(prevLiquidity));

//         uint256 currentToken0Balance = IERC20(KannonV1.WETH9()).balanceOf(poolLogAddrState);
//         uint256 currentToken1Balance = IERC20(TOKEN_ADDRESS).balanceOf(poolLogAddrState);
//         logChange("WETH Balance in Pool", currentToken0Balance, prevToken0Balance);
//         logChange("Token Balance in Pool", currentToken1Balance, prevToken1Balance);

//         uint256 currentUserETHBalance = user.balance;
//         uint256 currentUserTokenBalance = KannonV1.getTokenBalance(TOKEN_ADDRESS, user);
//         logChange("User ETH Balance", currentUserETHBalance, prevUserETHBalance);
//         logChange("User Token Balance", currentUserTokenBalance, prevUserTokenBalance);

//         (,,,, uint256 withdrawableLiquidity,,, uint128 liquidity) = KannonV1.tokenInfo(TOKEN_ADDRESS);

//         console.log("TokenInfo Changes:");
//         logChange("Withdrawable Liquidity", withdrawableLiquidity, withdrawableLiquidity);
//         logChange("Liquidity", uint256(liquidity), uint256(liquidity));
//     }

//     function logChange(string memory label, uint256 current, uint256 previous) internal view {
//         if (current >= previous) {
//             console.log("%s: [%s] (+%s)", label, current, current - previous);
//         } else {
//             console.log("%s: [%s] (-%s)", label, current, previous - current);
//         }
//     }
// }
