// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import {Test, console2} from "forge-std/Test.sol";
// import {IStargate, SendParam, MessagingFee} from "@stargatefinance/stg-evm-v2/src/interfaces/IStargate.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {IWETH} from "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

// contract StargateSwapTest is Test {
//     // Environment variables
//     string SEPOLIA_RPC_URL = vm.envString("SEPOLIA_RPC_URL");
//     string ARBITRUM_SEPOLIA_RPC_URL = vm.envString("ARBITRUM_SEPOLIA_RPC_URL");
//     uint256 SEPOLIA_PRIVATE_KEY = vm.envUint("SEPOLIA_PRIVATE_KEY");

//     // Addresses
//     address STARGATE_ROUTER_SEPOLIA = vm.envAddress("SEPOLIA_STARGATE_ROUTER");
//     address STARGATE_ROUTER_ARB_SEPOLIA = vm.envAddress("ARBITRUM_SEPOLIA_STARGATE_ROUTER");
//     address WETH_SEPOLIA = vm.envAddress("SEPOLIA_WETH9");
//     address WETH_ARB_SEPOLIA = vm.envAddress("ARBITRUM_SEPOLIA_WETH9");

//     IStargate stargateSepoliaRouter;
//     IWETH wethSepolia;

//     // Test parameters
//     address user;
//     uint256 swapAmount = 0.1 ether;
//     uint32 dstChainId = 421614; // Arbitrum Sepolia chain ID

//     function setUp() public {
//         // Fork Sepolia testnet
//         vm.createSelectFork(SEPOLIA_RPC_URL);

//         stargateSepoliaRouter = IStargate(STARGATE_ROUTER_SEPOLIA);
//         wethSepolia = IWETH(WETH_SEPOLIA);

//         // Set up user from private key
//         user = vm.addr(SEPOLIA_PRIVATE_KEY);

//         // Fund the user with ETH
//         vm.deal(user, 1 ether);
//     }

//     function testStargateSwap() public {
//         // Wrap ETH to WETH
//         vm.startPrank(user);
//         wethSepolia.deposit{value: swapAmount}();
//         wethSepolia.approve(address(stargateSepoliaRouter), swapAmount);

//         // Prepare swap parameters
//         SendParam memory sendParam = SendParam({
//             dstEid: dstChainId,
//             to: bytes32(uint256(uint160(user))), // Convert user address to bytes32
//             amountLD: swapAmount,
//             minAmountLD: swapAmount,
//             extraOptions: new bytes(0),
//             composeMsg: new bytes(0),
//             oftCmd: "" // Use taxi mode for simplicity
//         });

//         // Quote the messaging fee
//         MessagingFee memory messagingFee = stargateSepoliaRouter.quoteSend(sendParam, false);

//         // Perform the swap
//         stargateSepoliaRouter.sendToken{value: messagingFee.nativeFee}(sendParam, messagingFee, user);
//         vm.stopPrank();

//         // Switch to Arbitrum Sepolia fork
//         vm.createSelectFork(ARBITRUM_SEPOLIA_RPC_URL);

//         // Check the balance on Arbitrum Sepolia
//         IERC20 wethArbSepolia = IERC20(WETH_ARB_SEPOLIA);
//         uint256 balanceAfterSwap = wethArbSepolia.balanceOf(user);

//         // Assert that the user received the swapped amount (minus fees)
//         assertGt(balanceAfterSwap, 0, "User should have received WETH on Arbitrum Sepolia");
//         assertApproxEqRel(balanceAfterSwap, swapAmount, 0.05e18, "Received amount should be close to sent amount");
//     }
// }
