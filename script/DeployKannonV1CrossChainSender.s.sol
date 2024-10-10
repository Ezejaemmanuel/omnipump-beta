// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {KannonV1CrossChainSender} from "../src/kannon_v1_crosschain_sender.sol";

contract DeployKannonV1CrossChainSender is Script {
    struct DeploymentInfo {
        uint256 chainId;
        address endpointV2;
    }

    DeploymentInfo public info;

    function run() external {
        info.chainId = block.chainid;
        // require(
        //     info.chainId == 11155111 || info.chainId == 11155420, "This script is only for Sepolia or Optimism Sepolia"
        // );
        console.log("Chain ID:", info.chainId);

        uint256 deployerPrivateKey = getPrivateKey();
        setAddressesFromEnv();

        vm.startBroadcast(deployerPrivateKey);
        address deployedContract = deployKannonV1CrossChainSender();
        vm.stopBroadcast();

        console.log("KannonV1CrossChainSender deployed at:", deployedContract);
        console.log("Copy this address for use in the third script.");
    }

    function deployKannonV1CrossChainSender() internal returns (address) {
        KannonV1CrossChainSender sender = new KannonV1CrossChainSender(info.endpointV2, 1);
        return address(sender);
    }

    function getPrivateKey() internal view returns (uint256) {
        if (info.chainId == 11155111) {
            return vm.envUint("SEPOLIA_PRIVATE_KEY");
        } else if (info.chainId == 11155420) {
            return vm.envUint("OPTIMISM_SEPOLIA_PRIVATE_KEY");
        } else if (info.chainId == 421614) {
            return vm.envUint("ARBITRUM_SEPOLIA_PRIVATE_KEY");
        } else {
            revert("Unsupported chain ID");
        }
    }

    function setAddressesFromEnv() internal {
        if (info.chainId == 11155111) {
            info.endpointV2 = vm.envAddress("SEPOLIA_STARGATE_ENDPOINT_V2");
        } else if (info.chainId == 11155420) {
            info.endpointV2 = vm.envAddress("OPTIMISM_SEPOLIA_STARGATE_ENDPOINT_V2");
        } else if (info.chainId == 421614) {
            info.endpointV2 = vm.envAddress("ARBITRUM_SEPOLIA_STARGATE_ENDPOINT_V2");
        }
    }
}
