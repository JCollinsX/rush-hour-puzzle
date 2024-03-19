import { HardhatUserConfig, vars } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-prettier";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    "sepolia": {
      url: "https://eth-sepolia.api.onfinality.io/public",
      accounts: [vars.get("PRIVATE_KEY")],
    }
  },
  etherscan: {
    apiKey: {
      sepolia: vars.get("ETHERSCAN_API_KEY"),
    },
  }
};

export default config;
