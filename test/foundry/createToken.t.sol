// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import {Test, console} from "forge-std/Test.sol";
// import {MainEngine} from "../../src/mainEngine.sol";
// import {DeployMainEngine} from "../../script/deployMainEngine.s.sol";
// import {CustomToken} from "../../src/customToken.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

// contract MainEngineCreateTokenTest is Test {
//     MainEngine public mainEngine;
//     address public deployer;
//     address public user;

//     function setUp() public {
//         console.log("setUp - Starting setup");

//         console.log("setUp - Forked Sepolia at block:", block.number);

//         deployer = makeAddr("deployer");
//         user = makeAddr("user");
//         console.log("setUp - Created deployer address:", deployer);
//         console.log("setUp - Created user address:", user);

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

//     function testTokenCreation() public {
//         console.log("createTestToken - Starting token creation");

//         vm.startPrank(user);
//         console.log("createTestToken - Started prank as user:", user);

//         string memory name = "Test Token";
//         string memory symbol = "TST";
//         string memory description = "A test token";
//         string memory imageUrl = "https://example.com/image.png";
//         string memory twitter = "https://example.com/image.png";
//         string memory telegram = "https://example.com/image.png";
//         string memory website = "https://example.com/image.png";
//         uint256 initialSupply = 0.01 * 1e18; // 1 million tokens

//         console.log("createTestToken - Creating token");
//         address tokenAddress = mainEngine.createTokenForTest(
//             name, symbol, description, imageUrl, twitter, telegram, website, initialSupply
//         );
//         console.log("createTestToken - Token created at address:", tokenAddress);

//         CustomToken testToken = CustomToken(tokenAddress);

//         // Verify token creation
//         assertEq(testToken.name(), name, "Token name mismatch");
//         assertEq(testToken.symbol(), symbol, "Token symbol mismatch");
//         assertEq(testToken.getDescription(), description, "Token description mismatch");
//         assertEq(testToken.getImageUrl(), imageUrl, "Token image URL mismatch");
//         assertEq(testToken.totalSupply(), initialSupply, "Token initial supply mismatch");
//         assertEq(testToken.owner(), address(mainEngine), "Token owner should be the MainEngine");

//         console.log("createTestToken - Token creation verified");

//         vm.stopPrank();
//         console.log("createTestToken - Stopped prank");
//     }
// }
