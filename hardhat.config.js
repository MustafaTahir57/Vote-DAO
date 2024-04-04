require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
    bsc: {
      url: 'https://bsc-testnet.publicnode.com',
      accounts: ['Your Private key'],
    },
  }
};
