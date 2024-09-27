// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import "forge-std/Test.sol";
// import {KannonV1} from "../../src/newKannonV1.sol";
// import {DeployKannonV1} from "../../script/deployKannonV1.s.sol";

// contract SqrtFuzzTest is Test {
//     KannonV1 public KannonV1;
//     address public deployer;
//     address public user;

//     function setUp() public {
//         console.log("setUp - Starting setup");

//         vm.createSelectFork(sepoliaRpcUrl);
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
//         console.log("setUp - KannonV1 swapRouter address:", address(KannonV1.swapRouter()));
//         console.log("setUp - KannonV1 WETH9 address:", KannonV1.WETH9());

//         console.log("setUp - Setup completed");
//     }

//     function testSqrtFuzzed(uint256 x) public {
//         uint256 y = KannonV1.sqrt(x);

//         // Test basic properties
//         assertLe(y * y, x, "y^2 should be less than or equal to x");
//         assertLt(x, (y + 1) * (y + 1), "x should be less than (y+1)^2");

//         // Test for perfect squares
//         if (y * y == x) {
//             assertEq(y * y, x, "Result should be exact for perfect squares");
//         }

//         // Test for small numbers
//         if (x <= 3) {
//             if (x == 0) assertEq(y, 0, "sqrt(0) should be 0");
//             if (x == 1) assertEq(y, 1, "sqrt(1) should be 1");
//             if (x == 2 || x == 3) assertEq(y, 1, "sqrt(2) and sqrt(3) should be 1");
//         }

//         // Test for large numbers
//         if (x > type(uint128).max) {
//             assertTrue(y > 18446744073709551615, "sqrt of numbers > 2^128 should be > 2^64 - 1");
//         }

//         // Test for numbers close to max uint256
//         if (x > type(uint256).max - 1000) {
//             assertEq(y, 340282366920938463463374607431768211455, "Incorrect sqrt for numbers close to max uint256");
//         }

//         // Test for monotonicity
//         if (x > 0) {
//             uint256 prevY = KannonV1.sqrt(x - 1);
//             assertGe(y, prevY, "sqrt should be monotonically increasing");
//         }

//         // Test for precision
//         uint256 lowerBound = y * y;
//         uint256 upperBound = (y + 1) * (y + 1);
//         assertTrue(x >= lowerBound && x < upperBound, "x should be within [y^2, (y+1)^2)");

//         // Test for gas efficiency (this is a rough estimate)
//         uint256 gasStart = gasleft();
//         KannonV1.sqrt(x);

//         // Test for consistency with a different implementation
//         uint256 altY = alternativeSqrt(x);
//         assertEq(y, altY, "Result should be consistent with alternative implementation");
//     }

//     // Alternative sqrt implementation for comparison
//     function alternativeSqrt(uint256 x) internal pure returns (uint256) {
//         if (x == 0) return 0;
//         uint256 xx = x;
//         uint256 r = 1;
//         if (xx >= 0x100000000000000000000000000000000) {
//             xx >>= 128;
//             r <<= 64;
//         }
//         if (xx >= 0x10000000000000000) {
//             xx >>= 64;
//             r <<= 32;
//         }
//         if (xx >= 0x100000000) {
//             xx >>= 32;
//             r <<= 16;
//         }
//         if (xx >= 0x10000) {
//             xx >>= 16;
//             r <<= 8;
//         }
//         if (xx >= 0x100) {
//             xx >>= 8;
//             r <<= 4;
//         }
//         if (xx >= 0x10) {
//             xx >>= 4;
//             r <<= 2;
//         }
//         if (xx >= 0x4) r <<= 1;
//         r = (r + x / r) >> 1;
//         r = (r + x / r) >> 1;
//         r = (r + x / r) >> 1;
//         r = (r + x / r) >> 1;
//         r = (r + x / r) >> 1;
//         r = (r + x / r) >> 1;
//         r = (r + x / r) >> 1; // Seven iterations should be enough
//         uint256 r1 = x / r;
//         return r < r1 ? r : r1;
//     }
// }
