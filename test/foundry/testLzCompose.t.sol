// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import {Test, console} from "forge-std/Test.sol";
// import {MainEngine} from "../../src/eventsMainEngine.sol";
// import {CustomToken} from "../../src/customToken.sol";
// import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
// import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
// import {DeployMainEngine} from "../../script/deployMainEngine.s.sol";
// import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
// import {Vm} from "forge-std/Test.sol";
// import {OFTComposeMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTComposeMsgCodec.sol";

// contract MainEngineTest is Test {
//     MainEngine public mainEngine;
//     address public user;
//     // uint256 constant INITIAL_ETH = 0.1 ether;
//     uint256 constant MIN_CREATE_COST = 0.0001 ether;
//     address public deployer;
//     uint256 constant INITIAL_TOKEN_AMOUNT = 100 ether; // 1000 tokens
//     uint256 constant ETH_AMOUNT = 100 ether;

//     function setUp() public {
//         console.log("setUp - Starting setup");

//         console.log("setUp - Forked Sepolia at block:", block.number);

//         deployer = makeAddr("deployer");
//         user = makeAddr("user");
//         console.log("setUp - Created deployer address:", deployer);
//         console.log("setUp - Created user address:", user);
//         vm.deal(user, 1000 ether);
//         DeployMainEngine deployScript = new DeployMainEngine();

//         console.log("setUp - Created DeployMainEngine instance at:", address(deployScript));

//         (mainEngine,) = deployScript.run();
//         console.log("setUp - Ran DeployMainEngine script");
//         console.log("setUp - MainEngine deployed at:", address(mainEngine));

//         console.log("setUp - MainEngine factory address:", address(mainEngine.factory()));
//         console.log(
//             "setUp - MainEngine nonfungiblePositionManager address:", address(mainEngine.nonfungiblePositionManager())
//         );
//         console.log("setUp - MainEngine swapRouter address:", address(mainEngine.swapRouter02()));
//         console.log("setUp - MainEngine WETH9 address:", mainEngine.WETH9());

//         console.log("setUp - Setup completed");
//     }

//    function testLzComposeTokenCreationAndLiquidity() public {
//     console.log("testLzComposeTokenCreationAndLiquidity - Starting test");

//     // Prepare lzCompose parameters
//     address from = mainEngine.stargatePoolNative();
//     address endpointv2 = mainEngine.endpointV2();
//     bytes32 guid = bytes32(0);
//     uint256 amountLD = 100 ether; // Amount of ETH to be used for liquidity

//     string memory name = "Test Token";
//     string memory symbol = "TST";
//     string memory description = "A test token";
//     string memory imageUrl = "https://example.com/image.png";
//     string memory twitter = "https://twitter.com/test";
//     string memory telegram = "https://t.me/test";
//     string memory website = "https://test.com";
//     uint256 initialSupply = 1000 ether;
//     uint256 lockedLiquidityPercentage = 50;

//     console.log("Preparing compose message");
//     bytes memory composeMsg = abi.encodePacked(
//         bytes1(0x00),
//         abi.encode(
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
//         )
//     );

//     console.log("Preparing lzCompose message");
//     bytes memory message = abi.encodePacked(
//         uint8(2), // COMPOSED_TYPE
//         uint32(1), // srcEid (assuming 1 for this test)
//         abi.encodePacked(amountLD),
//         composeMsg
//     );

//     address executor = address(0);
//     bytes memory extraData = "";

//     console.log("Executing lzCompose");
//     vm.deal(endpointv2, amountLD);
//     vm.prank(endpointv2);
//     vm.recordLogs();
//     mainEngine.lzCompose{value: amountLD}(from, guid, message, executor, extraData);

//     console.log("lzCompose executed, processing logs");
//     Vm.Log[] memory entries = vm.getRecordedLogs();
//     address tokenAddress;
//     for (uint256 i = 0; i < entries.length; i++) {
//         if (entries[i].topics[0] == keccak256("AdditionalTokenData(address,string,string,string,string,string,string,string,uint256)")) {
//             tokenAddress = address(uint160(uint256(entries[i].topics[1])));
//             console.log("Token created at address:", tokenAddress);
//             break;
//         }
//     }
//     require(tokenAddress != address(0), "AdditionalTokenData event not found");

//     console.log("Verifying token details");
//     CustomToken token = CustomToken(tokenAddress);
//     assertEq(token.name(), name, "Token name mismatch");
//     assertEq(token.symbol(), symbol, "Token symbol mismatch");
//     assertEq(token.totalSupply(), initialSupply, "Initial supply mismatch");

//     console.log("Verifying token info in MainEngine");
//     (
//         address creator,
//         bool initialLiquidityAdded,
//         uint256 positionId,
//         uint256 storedLockedLiquidityPercentage,
//         uint256 withdrawableLiquidity,
//         uint256 creationTime,
//         address poolAddress,
//         uint128 liquidity
//     ) = mainEngine.tokenInfo(tokenAddress);

//     console.log("Creator:", creator);
//     console.log("Initial liquidity added:", initialLiquidityAdded);
//     console.log("Position ID:", positionId);
//     console.log("Locked liquidity percentage:", storedLockedLiquidityPercentage);
//     console.log("Withdrawable liquidity:", withdrawableLiquidity);
//     console.log("Creation time:", creationTime);
//     console.log("Pool address:", poolAddress);
//     console.log("Liquidity:", liquidity);

//     assertEq(creator, user, "Creator mismatch");
//     assertTrue(initialLiquidityAdded, "Initial liquidity not added");
//     assertGt(positionId, 0, "Invalid position ID");
//     assertEq(storedLockedLiquidityPercentage, lockedLiquidityPercentage, "Locked liquidity percentage mismatch");
//     assertGt(withdrawableLiquidity, 0, "No withdrawable liquidity");
//     assertEq(creationTime, block.timestamp, "Creation time mismatch");
//     assertTrue(poolAddress != address(0), "Pool not created");
//     assertGt(liquidity, 0, "No liquidity added");

//     console.log("Verifying pool setup and liquidity");
//     IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
//     uint24 poolFee = pool.fee();
//     uint128 poolLiquidity = pool.liquidity();
//     console.log("Pool fee:", poolFee);
//     console.log("Pool liquidity:", poolLiquidity);
//     assertEq(poolFee, 3000, "Pool fee mismatch");
//     assertGt(poolLiquidity, 0, "No liquidity in pool");

//     console.log("testLzComposeTokenCreationAndLiquidity - Test completed successfully");
// }
// }
