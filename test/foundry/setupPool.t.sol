// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.25;

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

//     function createTestToken() internal returns (address) {
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

//         return tokenAddress;
//     }

//     // function testSqrtLargeNumber() public {
//     //     assertEq(mainEngine.sqrt(1000000), 1000, "Square root of 1,000,000 should be 1,000");
//     // }

//     function testSetupPool() public {
//         console.log("testSetupPool - Starting test");

//         // Create a test token
//         address tokenAddress = createTestToken();
//         console.log("testSetupPool - Test token created at:", tokenAddress);

//         vm.startPrank(user);
//         console.log("testSetupPool - Started prank as user:", user);

//         // Setup the pool with a specified amount of ETH
//         uint256 ethAmount = 1 ether; // Example ETH amount
//         console.log("testSetupPool - Setting up pool with ETH amount:", ethAmount);
//         mainEngine.testSetupPool{value: 0.01 ether}(tokenAddress);

//         // Verify pool setup
//         (address creator,,,,,, address poolAddress,) = mainEngine.tokenInfo(tokenAddress);
//         console.log("testSetupPool - Verifying pool setup");
//         console.log("testSetupPool - Pool address:", poolAddress);

//         assertEq(creator, user, "Token creator mismatch");
//         assertTrue(poolAddress != address(0), "Pool address should not be zero");

//         // Verify pool properties
//         IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
//         console.log("testSetupPool - Verifying pool properties");
//         console.log("testSetupPool - Pool token0:", pool.token0());
//         console.log("testSetupPool - Pool token1:", pool.token1());
//         console.log("testSetupPool - Pool fee:", pool.fee());

//         assertTrue(
//             pool.token0() == tokenAddress || pool.token1() == tokenAddress, "Pool should contain the created token"
//         );
//         assertTrue(
//             pool.token0() == mainEngine.WETH9() || pool.token1() == mainEngine.WETH9(), "Pool should contain WETH9"
//         );
//         assertEq(pool.fee(), mainEngine.poolFee(), "Pool fee mismatch");

//         // Verify factory state
//         address factoryPoolAddress = mainEngine.factory().getPool(pool.token0(), pool.token1(), mainEngine.poolFee());
//         console.log("testSetupPool - Verifying factory state");
//         console.log("testSetupPool - Factory pool address:", factoryPoolAddress);

//         assertEq(factoryPoolAddress, poolAddress, "Factory pool address mismatch");

//         vm.stopPrank();
//         console.log("testSetupPool - Stopped prank");
//         console.log("testSetupPool - Test completed successfully");
//     }
// }
