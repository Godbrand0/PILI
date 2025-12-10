require("@nomicfoundation/hardhat-toolbox");
require("dotenv/config");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    fhenix: {
      url: process.env.FHENIX_RPC_URL || "https://api.helium.fhenix.zone",
      chainId: 8008420,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
  },
  paths: {
    sources: "./src",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
};
