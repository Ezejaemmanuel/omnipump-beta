// pragma solidity ^0.8.19;

// import {Script} from "forge-std/Script.sol";
// import {console} from "forge-std/console.sol";
// import {KannonV1} from "../src/kannon_v1.sol";
// import {KannonV1CrossChainSender} from "../src/kannon_v1_crosschain_sender.sol";

// contract SetPeers is Script {
//     address public kannonV1Address;
//     address public sepoliaCrossChainSenderAddress;
//     address public optimismSepoliaCrossChainSenderAddress;

//     // LayerZero v2 EIDs
//     uint32 constant ARBITRUM_SEPOLIA_EID = 40231;
//     uint32 constant SEPOLIA_EID = 40161;
//     uint32 constant OPTIMISM_SEPOLIA_EID = 40232;

//     function run() external {
//         uint256 chainId = block.chainid;
//         console.log("Setting peers for chain ID:", chainId);

//         // Set these addresses manually before running the script
//         kannonV1Address = 0x...; // KannonV1 address on Arbitrum Sepolia
//         sepoliaCrossChainSenderAddress = 0x...; // KannonV1CrossChainSender address on Sepolia
//         optimismSepoliaCrossChainSenderAddress = 0x...; // KannonV1CrossChainSender address on Optimism Sepolia

//         uint256 deployerPrivateKey = getPrivateKey(chainId);

//         vm.startBroadcast(deployerPrivateKey);

//         if (chainId == 421614) { // Arbitrum Sepolia
//             setPeersForKannonV1();
//         } else if (chainId == 11155111) { // Sepolia
//             setPeersForCrossChainSender(SEPOLIA_EID, sepoliaCrossChainSenderAddress);
//         } else if (chainId == 11155420) { // Optimism Sepolia
//             setPeersForCrossChainSender(OPTIMISM_SEPOLIA_EID, optimismSepoliaCrossChainSenderAddress);
//         } else {
//             revert("Unsupported chain ID");
//         }

//         vm.stopBroadcast();
//     }

//     function setPeersForKannonV1() internal {
//         KannonV1 kannonV1 = KannonV1(payable(kannonV1Address));

//         // Set peer for Sepolia
//         kannonV1.setPeer(SEPOLIA_EID, bytes32(uint256(uint160(sepoliaCrossChainSenderAddress))));
//         console.log("Set peer for Sepolia on KannonV1");

//         // Set peer for Optimism Sepolia
//         kannonV1.setPeer(OPTIMISM_SEPOLIA_EID, bytes32(uint256(uint160(optimismSepoliaCrossChainSenderAddress))));
//         console.log("Set peer for Optimism Sepolia on KannonV1");
//     }

//     function setPeersForCrossChainSender(uint32 sourceEid, address crossChainSenderAddress) internal {
//         KannonV1CrossChainSender crossChainSender = KannonV1CrossChainSender(crossChainSenderAddress);
//         crossChainSender.setPeer(ARBITRUM_SEPOLIA_EID, bytes32(uint256(uint160(kannonV1Address))));
//         console.log("Set peer for Arbitrum Sepolia on CrossChainSender for EID:", sourceEid);
//     }

//     function getPrivateKey(uint256 chainId) internal view returns (uint256) {
//         if (chainId == 421614) { // Arbitrum Sepolia
//             return vm.envUint("ARBITRUM_SEPOLIA_PRIVATE_KEY");
//         } else if (chainId == 11155111) { // Sepolia
//             return vm.envUint("SEPOLIA_PRIVATE_KEY");
//         } else if (chainId == 11155420) { // Optimism Sepolia
//             return vm.envUint("OPTIMISM_SEPOLIA_PRIVATE_KEY");
//         } else {
//             revert("Unsupported chain ID");
//         }
//     }
// }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {KannonV1} from "../src/kannon_v1.sol";
import {KannonV1CrossChainSender} from "../src/kannon_v1_crosschain_sender.sol";

contract SetPeers is Script {
    address public kannonV1Address;
    address public sepoliaCrossChainSenderAddress;
    address public optimismSepoliaCrossChainSenderAddress;

    // LayerZero v2 EIDs
    uint32 constant ARBITRUM_SEPOLIA_EID = 40231;
    uint32 constant SEPOLIA_EID = 40161;
    uint32 constant OPTIMISM_SEPOLIA_EID = 40232;

    function run() external {
        uint256 chainId = block.chainid;
        console.log("Setting peers for chain ID:", chainId);

        // Set these addresses manually before running the script
        kannonV1Address = 0xCBE7D5711DFE8B499A1aC3cfAfA90e5413b0E936; // KannonV1 address on Arbitrum Sepolia
        sepoliaCrossChainSenderAddress = 0x7494969735C497E6c2cf7Dc064DA6e2E56a526ba; // KannonV1CrossChainSender address on Sepolia
        optimismSepoliaCrossChainSenderAddress = 0xfbDF05c9729655316759D65e4EA14c0BBD921B17; // KannonV1CrossChainSender address on Optimism Sepolia

        uint256 deployerPrivateKey = getPrivateKey(chainId);

        vm.startBroadcast(deployerPrivateKey);

        if (chainId == 421614) {
            // Arbitrum Sepolia
            setPeersForKannonV1();
        } else if (chainId == 11155111) {
            // Sepolia
            setPeersForCrossChainSender(SEPOLIA_EID, sepoliaCrossChainSenderAddress);
        } else if (chainId == 11155420) {
            // Optimism Sepolia
            setPeersForCrossChainSender(OPTIMISM_SEPOLIA_EID, optimismSepoliaCrossChainSenderAddress);
        } else {
            revert("Unsupported chain ID");
        }

        vm.stopBroadcast();
    }

    function setPeersForKannonV1() internal {
        KannonV1 kannonV1 = KannonV1(payable(kannonV1Address));

        // Set peer for Sepolia
        kannonV1.setPeer(SEPOLIA_EID, addressToBytes32(sepoliaCrossChainSenderAddress));
        console.log("Set peer for Sepolia on KannonV1");

        // Set peer for Optimism Sepolia
        kannonV1.setPeer(OPTIMISM_SEPOLIA_EID, addressToBytes32(optimismSepoliaCrossChainSenderAddress));
        console.log("Set peer for Optimism Sepolia on KannonV1");
    }

    function setPeersForCrossChainSender(uint32 sourceEid, address crossChainSenderAddress) internal {
        KannonV1CrossChainSender crossChainSender = KannonV1CrossChainSender(crossChainSenderAddress);
        crossChainSender.setPeer(ARBITRUM_SEPOLIA_EID, addressToBytes32(kannonV1Address));
        console.log("Set peer for Arbitrum Sepolia on CrossChainSender for EID:", sourceEid);
    }

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function getPrivateKey(uint256 chainId) internal view returns (uint256) {
        if (chainId == 421614) {
            // Arbitrum Sepolia
            return vm.envUint("ARBITRUM_SEPOLIA_PRIVATE_KEY");
        } else if (chainId == 11155111) {
            // Sepolia
            return vm.envUint("SEPOLIA_PRIVATE_KEY");
        } else if (chainId == 11155420) {
            // Optimism Sepolia
            return vm.envUint("OPTIMISM_SEPOLIA_PRIVATE_KEY");
        } else {
            revert("Unsupported chain ID");
        }
    }
}
