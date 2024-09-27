// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import {Test, console} from "forge-std/Test.sol";
// import {KannonV1} from "../../src/KannonV1.sol";
// import {DeployKannonV1} from "../../script/deployKannonV1.s.sol";
// import {CustomToken} from "../../src/customToken.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

// contract KannonV1CreateTokenTest is Test {
//     KannonV1 public KannonV1;
//     address public deployer;
//     address public user;

//     function setUp() public {
//         console.log("setUp - Starting setup");

//         console.log("setUp - Forked Sepolia at block:", block.number);

//         deployer = makeAddr("deployer");
//         user = makeAddr("user");
//         console.log("setUp - Created deployer address:", deployer);
//         console.log("setUp - Created user address:", user);

//         DeployKannonV1 deployScript = new DeployKannonV1();
//         console.log("setUp - Created DeployKannonV1 instance at:", address(deployScript));

//         (KannonV1,) = deployScript.run();
//         console.log("setUp - Ran DeployKannonV1 script");
//         console.log("setUp - KannonV1 deployed at:", address(KannonV1));

//         console.log("setUp - KannonV1 factory address:", address(KannonV1.factory()));
//         console.log(
//             "setUp - KannonV1 nonfungiblePositionManager address:", address(KannonV1.nonfungiblePositionManager())
//         );
//         console.log("setUp - KannonV1 swapRouter address:", address(KannonV1.swapRouter02()));
//         console.log("setUp - KannonV1 WETH9 address:", KannonV1.WETH9());

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
//         address tokenAddress = KannonV1.createTokenForTest(
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
//         assertEq(testToken.owner(), address(KannonV1), "Token owner should be the KannonV1");

//         console.log("createTestToken - Token creation verified");

//         vm.stopPrank();
//         console.log("createTestToken - Stopped prank");
//     }
// }
