// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import {Test, console,Vm} from "forge-std/Test.sol";
// import {MainEngine} from "../../src/mainEngine.sol";
// import {DeployMainEngine} from "../../script/deployMainEngine.s.sol";
// import {CustomToken} from "../../src/customToken.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
// import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
// import {IQuoterV2} from "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";
// import {LiquidityAmounts} from "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

// contract MainEngineLZComposeTest is Test {
//     MainEngine public mainEngine;
//     address public deployer;
//     address public user;
//     address public TOKEN_ADDRESS;
//     uint24 public constant FEE = 3000;
//     uint256 public constant SWAP_AMOUNT = 1 ether;
//     uint256 constant INITIAL_TOKEN_AMOUNT = 1000000000 ether;
//     uint256 constant ETH_AMOUNT = 100000000 ether;
//     IQuoterV2 public quoterV2;
//     address public WETH9;

//     event TokenTrade(
//         address indexed tokenAddress,
//         address indexed trader,
//         MainEngine.TradeType tradeType,
//         uint256 inputAmount,
//         uint256 outputAmount,
//         uint256 timestamp
//     );

//     event TokenUpdate(
//         address indexed tokenAddress,
//         address indexed creator,
//         uint160 sqrtPriceX96,
//         uint256 tokenPrice,
//         uint128 liquidity,
//         uint256 ethReserve,
//         uint256 tokenReserve,
//         uint256 totalSupply,
//         uint256 lockedLiquidityPercentage,
//         uint256 withdrawableLiquidity,
//         uint256 liquidatedLiquidity,
//         uint256 timestamp
//     );

//     function setUp() public {
//         deployer = makeAddr("deployer");
//         user = makeAddr("user");
//         vm.deal(deployer, 10000000000000000 ether);
//         vm.deal(user, 100000000000000000000 ether);

//         DeployMainEngine deployScript = new DeployMainEngine();
//         (mainEngine,) = deployScript.run();
//         WETH9 = mainEngine.WETH9();
//         vm.deal(address(mainEngine),5 ether);

//         // Create token and add liquidity
//         TOKEN_ADDRESS = createTokensAndAddLiquidity();
//     }

//     function createTokensAndAddLiquidity() internal returns (address) {
//         vm.startPrank(deployer);
//         address token = createToken("Test Token", "TST");
//         vm.stopPrank();
//         return token;
//     }

//     function createToken(string memory name, string memory symbol) internal returns (address) {
//         uint256 lockedLiquidityPercentage = 50;
//         string memory description = "A test token";
//         string memory imageUrl = "https://example.com/image.png";
//         string memory twitter = "https://twitter.com/example";
//         string memory telegram = "https://t.me/example";
//         string memory website = "https://example.com";
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

//     function testLZComposeSwapExactETHForTokensSuccess() public {
//         uint256 swapAmount = 0.1 ether;
//         address recipient = address(0x123);



//         vm.prank(address(mainEngine));
//         uint256 amountOut = mainEngine.exposed_lzComposeSwapExactETHForTokens(TOKEN_ADDRESS, swapAmount, recipient);

//         assertTrue(amountOut > 0, "Swap should return tokens");
//         assertGt(IERC20(TOKEN_ADDRESS).balanceOf(recipient), 0, "Recipient should receive tokens");
//     }

//     function testLZComposeSwapExactETHForTokensFailure() public {
//         uint256 swapAmount = 0.1 ether;
//         address recipient = makeAddr("user_failure");

//         // Simulate a swap failure by using an invalid token address
//         address invalidToken = makeAddr("fake_token");

     
//         vm.prank(address(mainEngine));
//         console.log("this is the reciepient balance before ",recipient.balance);

//         uint256 amountOut = mainEngine.exposed_lzComposeSwapExactETHForTokens(invalidToken, swapAmount, recipient);
//         console.log("this is the reciepient balance after ",recipient.balance);

//         assertEq(amountOut, 0, "Failed swap should return 0");
//         assertEq(recipient.balance, swapAmount, "Recipient should be refunded");
//     }

//     function testLZComposeSwapExactETHForTokensZeroAmount() public {
//         address recipient = makeAddr("recipient_user");

//         vm.expectRevert(MainEngine.MustSendETH.selector);
//         vm.prank(address(mainEngine));
//         mainEngine.exposed_lzComposeSwapExactETHForTokens(TOKEN_ADDRESS, 0, recipient);
//     }

//     function testLZComposeSwapExactETHForTokensRefundFailure() public {
//         uint256 swapAmount = 0.1 ether;
//         address payable badRecipient = payable(address(new RevertingContract()));

//         vm.expectRevert(MainEngine.TransferEthFailed.selector);
//         vm.prank(address(mainEngine));
//         mainEngine.exposed_lzComposeSwapExactETHForTokens(address(0x456), swapAmount, badRecipient);
//     }

//     function testLZComposeSwapExactETHForTokensEventData() public {
//         uint256 swapAmount = 0.1 ether;
//         address recipient = address(0x123);

//         vm.recordLogs();

//         vm.prank(address(mainEngine));
//         mainEngine.exposed_lzComposeSwapExactETHForTokens(TOKEN_ADDRESS, swapAmount, recipient);

//         Vm.Log[] memory entries = vm.getRecordedLogs();

//         assertEq(entries.length, 2, "Should emit 2 events");

//         // Check TokenTrade event
//         assertEq(entries[0].topics[0], keccak256("TokenTrade(address,address,uint8,uint256,uint256,uint256)"), "First event should be TokenTrade");
//         assertEq(address(uint160(uint256(entries[0].topics[1]))), TOKEN_ADDRESS, "TokenTrade event: incorrect token address");
//         assertEq(address(uint160(uint256(entries[0].topics[2]))), recipient, "TokenTrade event: incorrect recipient");

//         // Check TokenUpdate event
//         assertEq(entries[1].topics[0], keccak256("TokenUpdate(address,address,uint160,uint256,uint128,uint256,uint256,uint256,uint256,uint256,uint256,uint256)"), "Second event should be TokenUpdate");
//         assertEq(address(uint160(uint256(entries[1].topics[1]))), TOKEN_ADDRESS, "TokenUpdate event: incorrect token address");
//     }
// }

// contract RevertingContract {
//     receive() external payable {
//         revert("Always reverts");
//     }
// }


