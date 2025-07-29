import type { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
import "hardhat-gas-reporter";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
      metadata: {
        bytecodeHash: "none",
      },
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  etherscan: {
      apiKey: {
          mainnet: process.env.ETHERSCAN_API_KEY || "",
          bsc: process.env.BSCSCAN_API_KEY || "",
          bscTestnet: process.env.BSCSCAN_API_KEY || "",
      },
  },
  sourcify: {
      // Disabled by default
      // Doesn't need an API key
      enabled: true,
  },
  gasReporter: {
      enabled: true,
      showMethodSig: true,
      currency: "USD",
      token: "BNB",
      gasPriceApi:
          "https://api.bscscan.com/api?module=proxy&action=eth_gasPrice&apikey=" + process.env.BSCSCAN_API_KEY,
      coinmarketcap: process.env.CMC_API_KEY || "",
      noColors: true,
      reportFormat: "markdown",
      outputFile: "gasReport.md",
      forceTerminalOutput: true,
      L1: "binance",
      forceTerminalOutputFormat: "terminal",
    },
};

export default config;
