// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import {Test, console} from "forge-std/Test.sol";
// import {MainEngine} from "../../src/mainEngine.sol";
// import {CustomToken} from "../../src/customToken.sol";
// import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
// import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
// import {DeployMainEngine} from "../../script/deployMainEngine.s.sol";
// import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract MainEngineIntegrationTest is Test {
//     MainEngine public mainEngine;
//     address public deployer;
//     address public tokenAddress;
//     address public intermediateTokenAddress;
//     address[4] public users;
//     uint256 constant INITIAL_TOKEN_AMOUNT = 10000000000000 ether; // 100,000 tokens
//     uint256 constant ETH_AMOUNT = 100000000000 ether;
//     uint256 constant TOKEN_AMOUNT = 100 ether;

//     function setUp() public {
//         console.log("setUp - Starting setup");

//         console.log("setUp - Forked Sepolia at block:", block.number);

//         deployer = makeAddr("deployer");
//         // deployer = vm.envAddress("deployer__");
//         vm.deal(deployer, 10000000000000000 ether);
//         console.log("setUp - Deployer address:", deployer);

//         for (uint256 i = 0; i < 4; i++) {
//             users[i] = makeAddr(string(abi.encodePacked("user", i + 1)));
//             vm.deal(users[i], 10000000000000000 ether);
//             console.log("setUp - Created user", i + 1, "with address:", users[i]);
//         }

//         DeployMainEngine deployScript = new DeployMainEngine();
//         (mainEngine,) = deployScript.run();
//         console.log("setUp - MainEngine deployed at:", address(mainEngine));

//         assertTrue(address(mainEngine) != address(0), "MainEngine deployment failed");
//         console.log("setUp - Setup completed");
//     }

//     function testIntegrationSwaps() public {
//         console.log("testIntegrationSwaps - Starting integration test");

//         // Step 1: Create tokens and add initial liquidity
//         (tokenAddress, intermediateTokenAddress) = createTokensAndAddLiquidity();

//         assertTrue(tokenAddress != address(0), "Token1 creation failed");
//         assertTrue(intermediateTokenAddress != address(0), "Token2 creation failed");
//         console.log("testIntegrationSwaps - Tokens created successfully");

//         // Step 2: Perform swaps
//         performSwaps();

//         console.log("testIntegrationSwaps - Integration test completed");
//     }

//     function createTokensAndAddLiquidity() internal returns (address, address) {
//         console.log("createTokensAndAddLiquidity - Creating tokens and adding liquidity");
//         vm.startPrank(deployer);

//         address token1 = createToken("Test Token 1", "TST1");
//         address token2 = createToken("Test Token 2", "TST2");

//         console.log("createTokensAndAddLiquidity - Token 1 created at:", token1);
//         console.log("createTokensAndAddLiquidity - Token 2 created at:", token2);

//         vm.stopPrank();

//         uint256 token1Balance = IERC20(token1).balanceOf(address(mainEngine));
//         uint256 token2Balance = IERC20(token2).balanceOf(address(mainEngine));
//         console.log("createTokensAndAddLiquidity - MainEngine token1 balance:", token1Balance);
//         console.log("createTokensAndAddLiquidity - MainEngine token2 balance:", token2Balance);

//         assertEq(token1Balance, INITIAL_TOKEN_AMOUNT, "Initial token1 balance incorrect");
//         assertEq(token2Balance, INITIAL_TOKEN_AMOUNT, "Initial token2 balance incorrect");

//         return (token1, token2);
//     }

//     function nearestUsableTick(int24 tick, int24 tickSpacing) public pure returns (int24) {
//         require(tickSpacing > 0, "TICK_SPACING");
//         require(tick >= TickMath.MIN_TICK && tick <= TickMath.MAX_TICK, "TICK_BOUND");

//         int24 rounded = tick / tickSpacing * tickSpacing;
//         if (tick < 0 && tick % tickSpacing != 0) rounded -= tickSpacing;
//         return rounded;
//     }

//     function createToken(string memory name, string memory symbol) internal returns (address) {
//         console.log("createToken - Creating token:", name);

//         uint256 lockedLiquidityPercentage = 50; // 50%
//         string memory description = "A test token";
//         string memory imageUrl = "https://example.com/image.png";
//         string memory twitter = "https://example.com/image.png";
//         string memory telegram = "https://example.com/image.png";
//         string memory website = "https://example.com/image.png";
//         uint256 initialSupply = INITIAL_TOKEN_AMOUNT;

//         console.log("testcreateTokenAndAddLiquidity - Calling createTokenAndAddLiquidity");
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

//         console.log("createToken - Token created at:", tokenAddr);

//         assertTrue(tokenAddr != address(0), "Token creation failed");

//         (, bool initialLiquidityAdded,,,,, address pool,) = mainEngine.tokenInfo(tokenAddr);
//         assertTrue(initialLiquidityAdded, "Initial liquidity not added");
//         assertTrue(pool != address(0), "Pool not created");

//         console.log("createToken - Token info:");
//         console.log("  Initial liquidity added:", initialLiquidityAdded);
//         console.log("  Pool address:", pool);

//         return tokenAddr;
//     }

//     function performSwaps() internal {
//         console.log("performSwaps - Starting swap operations");

//         for (uint256 i = 0; i < 4; i++) {
//             address user = users[i];
//             console.log("performSwaps - Starting swaps for user:", user);

//             uint256 initialEthBalance = user.balance;
//             console.log("performSwaps - Initial ETH balance:", initialEthBalance);

//             vm.startPrank(user);

//             // Swap ETH for token1
//             uint256 token1Amount = swapEthForToken(tokenAddress, 10000 ether);
//             console.log("performSwaps - User swapped 0.1 ETH for", token1Amount, "of token1");
//             assertTrue(token1Amount > 0, "Failed to swap ETH for token1");

//             // Swap token1 for ETH
//             IERC20(tokenAddress).approve(address(mainEngine), token1Amount);
//             uint256 ethReceived = swapTokenForEth(tokenAddress, token1Amount);
//             console.log("performSwaps - User swapped token1 for ETH");
//             console.log("  Token1 amount:", token1Amount);
//             console.log("  ETH received:", ethReceived);
//             assertTrue(ethReceived > 0, "Failed to swap token1 for ETH");

//             // Swap ETH for token2
//             uint256 token2Amount = swapEthForToken(intermediateTokenAddress, ethReceived);
//             console.log("performSwaps - User swapped ETH for token2");
//             console.log("  ETH amount:", ethReceived);
//             console.log("  Token2 amount:", token2Amount);
//             assertTrue(token2Amount > 0, "Failed to swap ETH for token2");

//             // Swap token2 back to ETH
//             IERC20(intermediateTokenAddress).approve(address(mainEngine), token2Amount);
//             uint256 finalEthReceived = swapTokenForEth(intermediateTokenAddress, token2Amount);
//             console.log("performSwaps - User swapped token2 for ETH");
//             console.log("  Token2 amount:", token2Amount);
//             console.log("  ETH received:", finalEthReceived);
//             assertTrue(finalEthReceived > 0, "Failed to swap token2 for ETH");

//             uint256 finalEthBalance = user.balance;
//             console.log("performSwaps - Final ETH balance:", finalEthBalance);
//             console.log("performSwaps - ETH balance change:");
//             console.log("finalEthBalance:", finalEthBalance);
//             console.log("initialEthBalance:", initialEthBalance);
//             uint256 ethDifference = uint256(finalEthBalance) - uint256(initialEthBalance);
//             console.log("ETH difference:", ethDifference);
//             assertTrue(finalEthBalance < initialEthBalance, "ETH balance should decrease after swaps");

//             vm.stopPrank();
//         }

//         console.log("performSwaps - Swap operations completed");
//     }

//     function swapEthForToken(address tokenAddr, uint256 ethAmount) internal returns (uint256) {
//         console.log("swapEthForToken - Swapping", ethAmount, "ETH for token:", tokenAddr);
//         uint256 tokensBefore = IERC20(tokenAddr).balanceOf(msg.sender);
//         mainEngine.swapExactETHForTokens{value: ethAmount}(tokenAddr);
//         uint256 tokensAfter = IERC20(tokenAddr).balanceOf(msg.sender);
//         uint256 tokensReceived = tokensAfter - tokensBefore;
//         console.log("swapEthForToken - Received", tokensReceived, "tokens");
//         assertTrue(tokensReceived > 0, "No tokens received in ETH to token swap");
//         return tokensReceived;
//     }

//     function swapTokenForEth(address tokenAddr, uint256 tokenAmount) internal returns (uint256) {
//         console.log("swapTokenForEth - Swapping tokens for ETH");
//         console.log("  Token Amount:", tokenAmount);
//         console.log("  Token Address:", tokenAddr);
//         uint256 ethBefore = msg.sender.balance;
//         mainEngine.swapExactTokensForETH(tokenAddr, tokenAmount);
//         uint256 ethAfter = msg.sender.balance;
//         uint256 ethReceived = ethAfter - ethBefore;
//         console.log("swapTokenForEth - Received", ethReceived, "ETH");
//         assertTrue(ethReceived > 0, "No ETH received in token to ETH swap");
//         return ethReceived;
//     }
// }
