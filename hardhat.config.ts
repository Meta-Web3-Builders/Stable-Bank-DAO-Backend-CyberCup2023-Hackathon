require("@nomiclabs/hardhat-etherscan");
import "@nomiclabs/hardhat-ethers";
require("dotenv").config({ path: ".env" });

const ALCHEMY_mumbai_API_KEY_URL = process.env.ALCHEMY_mumbai_API_KEY_URL;
//contract address key
const ACCOUNT_PRIVATE_KEY = process.env.ACCOUNT_PRIVATE_KEY;

module.exports = {
  solidity: "0.8.17",
  networks: {
    mumbai: {
      url: ALCHEMY_mumbai_API_KEY_URL,
      accounts: [ACCOUNT_PRIVATE_KEY],
    }
  },
  etherscan: {
    apiKey: process.env.POLYGONSCAN_API_KEY
  }
};