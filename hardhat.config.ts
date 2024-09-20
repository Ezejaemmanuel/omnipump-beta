import * as dotenv from 'dotenv'

import '@nomicfoundation/hardhat-toolbox'
import { HardhatUserConfig } from 'hardhat/types'
// it will be able to use dependencies installed with forge install
import '@nomicfoundation/hardhat-foundry'
// import "hardhat-uniswap";
// require("@uniswap/hardhat-v3-deploy");
import "hardhat-uniswap";

// import "@uniswap/hardhat-v3-deploy";
dotenv.config()

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  
  networks: {
    hardhat: {

      blockGasLimit: 30_000_000,
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL,
      accounts: [process.env.PRIVATE_KEY!],
    }
  },
  solidity: {
    compilers: [
      {
        version: '0.8.26',
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 15000,
          },
        },
      },
    ],
  },

  // Avoid foundry cache conflict.
  paths: {
    sources: 'src', // Use ./src rather than ./contracts as Hardhat expects
    cache: 'hh-cache',
  },
}

export default config
