// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.20;

// import {KannonV1CrossChainSender} from "../../contracts/kannonV1-crosschain.sol";
// import {KannonV1} from "../../contracts/kannonV1.sol";
// import {
//     IOAppOptionsType3, EnforcedOptionParam
// } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
// import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
// import "forge-std/console.sol";
// import {TestHelperOz5} from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";
// import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
// import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
// import {ISwapRouter02} from "@uniswap/v3-swap-routers/contracts/interfaces/ISwapRouter02.sol";
// import {SendParam} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
// import {MessagingFee, Origin} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";

// contract KannonV1CrossChainTest is TestHelperOz5 {
//     using OptionsBuilder for bytes;

//     uint32 private aEid = 1;
//     uint32 private bEid = 2;

//     KannonV1CrossChainSender private aSender;
//     KannonV1CrossChainSender private bSender;
//     KannonV1 private aKannonV1;
//     KannonV1 private bKannonV1;

//     address private userA = address(0x1);
//     address private userB = address(0x2);
//     uint256 private initialBalance = 100 ether;

//     // Mock addresses for Uniswap contracts
//     IUniswapV3Factory private mockFactory = IUniswapV3Factory(address(0x3));
//     INonfungiblePositionManager private mockPositionManager = INonfungiblePositionManager(address(0x4));
//     ISwapRouter02 private mockSwapRouter = ISwapRouter02(address(0x5));
//     address private mockWETH9 = address(0x6);
//     address private mockStargatePoolNative = address(0x7);

//     function setUp() public virtual override {
//         vm.deal(userA, 1000 ether);
//         vm.deal(userB, 1000 ether);

//         super.setUp();
//         setUpEndpoints(2, LibraryType.UltraLightNode);

//         aSender = KannonV1CrossChainSender(
//             _deployOApp(type(KannonV1CrossChainSender).creationCode, abi.encode(address(endpoints[aEid]), uint64(1)))
//         );

//         bSender = KannonV1CrossChainSender(
//             _deployOApp(type(KannonV1CrossChainSender).creationCode, abi.encode(address(endpoints[bEid]), uint64(1)))
//         );

//         aKannonV1 = KannonV1(
//             payable(
//                 _deployOApp(
//                     type(KannonV1).creationCode,
//                     abi.encode(
//                         mockFactory,
//                         mockPositionManager,
//                         mockSwapRouter,
//                         mockWETH9,
//                         mockStargatePoolNative,
//                         address(endpoints[aEid]),
//                         uint64(1),
//                         300,
//                         300,
//                         400
//                     )
//                 )
//             )
//         );

//         bKannonV1 = KannonV1(
//             payable(
//                 _deployOApp(
//                     type(KannonV1).creationCode,
//                     abi.encode(
//                         mockFactory,
//                         mockPositionManager,
//                         mockSwapRouter,
//                         mockWETH9,
//                         mockStargatePoolNative,
//                         address(endpoints[bEid]),
//                         uint64(1),
//                         300,
//                         300,
//                         400
//                     )
//                 )
//             )
//         );

//         address[] memory oapps = new address[](4);
//         oapps[0] = address(aSender);
//         oapps[1] = address(bSender);
//         oapps[2] = address(aKannonV1);
//         oapps[3] = address(bKannonV1);
//         this.wireOApps(oapps);
//     }

//     function test_constructor() public {
//         assertEq(aSender.owner(), address(this));
//         assertEq(bSender.owner(), address(this));
//         assertEq(aKannonV1.owner(), address(this));
//         assertEq(bKannonV1.owner(), address(this));

//         assertEq(address(aSender.endpoint()), address(endpoints[aEid]));
//         assertEq(address(bSender.endpoint()), address(endpoints[bEid]));
//         assertEq(address(aKannonV1.endpoint()), address(endpoints[aEid]));
//         assertEq(address(bKannonV1.endpoint()), address(endpoints[bEid]));
//     }

//     function test_sendMessage() public {
//         bytes memory payload = abi.encode("Hello, Cross-Chain!");
//         bytes memory options = "";
//         uint256 nativeFee = 0.1 ether;

//         vm.prank(userA);
//         vm.expectEmit(true, false, false, true);
//         aSender.sendMessage{value: nativeFee}(
//             bEid, address(bKannonV1), options, payload, MessagingFee({nativeFee: nativeFee, lzTokenFee: 0})
//         );
//     }

//     function test_createTokenAndStartPresale_crossChain() public {
//         KannonV1.TokenPresaleParams memory params = KannonV1.TokenPresaleParams({
//             tokenParams: KannonV1.TokenParams({
//                 userAddress: address(0),
//                 name: "TestToken",
//                 symbol: "TT",
//                 description: "Test Token Description",
//                 imageUrl: "https://test.com/image.png",
//                 twitter: "@testtoken",
//                 telegram: "t.me/testtoken",
//                 website: "https://testtoken.com",
//                 initialSupply: 1000000 * 1e18
//             }),
//             ethTarget: 100 ether,
//             presaleDuration: 7 days
//         });

//         bytes memory payload = abi.encode(bytes1(0x03), abi.encode(params));
//         bytes memory options = "";
//         uint256 nativeFee = 0.1 ether;

//         vm.prank(userA);
//         aSender.sendMessage{value: nativeFee}(
//             bEid, address(bKannonV1), options, payload, MessagingFee({nativeFee: nativeFee, lzTokenFee: 0})
//         );

//         // Add assertions to verify the token creation and presale start on chain B
//         // This might require mocking some functions in the KannonV1 contract
//     }

//     function test_participateInPresale_crossChain() public {
//         // First, create a token and start presale
//         test_createTokenAndStartPresale_crossChain();

//         // Now, participate in the presale
//         address tokenAddress = bKannonV1.getLastCreatedToken();
//         uint256 participationAmount = 1 ether;

//         bytes memory payload = abi.encode(bytes1(0x01), abi.encode(tokenAddress, userB));
//         bytes memory options = "";
//         uint256 nativeFee = 0.1 ether;

//         vm.prank(userB);
//         aSender.sendMessage{value: nativeFee + participationAmount}(
//             bEid, address(bKannonV1), options, payload, MessagingFee({nativeFee: nativeFee, lzTokenFee: 0})
//         );

//         // Add assertions to verify the presale participation on chain B
//         // This might require mocking some functions in the KannonV1 contract
//     }

//     function test_swapExactETHForTokens_crossChain() public {
//         // First, create a token and start presale
//         test_createTokenAndStartPresale_crossChain();

//         // Now, swap ETH for tokens
//         address tokenAddress = bKannonV1.getLastCreatedToken();
//         uint256 swapAmount = 0.5 ether;

//         bytes memory payload = abi.encode(bytes1(0x01), abi.encode(tokenAddress, userA));
//         bytes memory options = "";
//         uint256 nativeFee = 0.1 ether;

//         vm.prank(userA);
//         aSender.sendMessage{value: nativeFee + swapAmount}(
//             bEid, address(bKannonV1), options, payload, MessagingFee({nativeFee: nativeFee, lzTokenFee: 0})
//         );

//         // Add assertions to verify the swap on chain B
//         // This might require mocking some functions in the KannonV1 contract
//     }

//     function test_swapExactTokensForETH_crossChain() public {
//         // First, create a token, start presale, and swap ETH for tokens
//         test_swapExactETHForTokens_crossChain();

//         // Now, swap tokens back to ETH
//         address tokenAddress = bKannonV1.getLastCreatedToken();
//         uint256 tokenAmount = 100 * 1e18; // Assuming 18 decimals

//         // Mock the token transfer and approval
//         vm.mockCall(
//             tokenAddress,
//             abi.encodeWithSelector(IERC20.transferFrom.selector, userA, address(bKannonV1), tokenAmount),
//             abi.encode(true)
//         );
//         vm.mockCall(
//             tokenAddress,
//             abi.encodeWithSelector(IERC20.approve.selector, address(mockSwapRouter), tokenAmount),
//             abi.encode(true)
//         );

//         vm.prank(userA);
//         bKannonV1.swapExactTokensForETH(tokenAddress, tokenAmount, aEid);

//         // Add assertions to verify the swap and ETH transfer back to chain A
//         // This might require mocking some functions in the KannonV1 contract
//     }

//     // Add more test cases as needed

//     // receive() external payable {}
// }
