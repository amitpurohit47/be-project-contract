// https://eth-goerli.g.alchemy.com/v2/Y1a76FQy1tAbHFLHdG4q7_xQYWf5u7m1

require("@nomiclabs/hardhat-waffle");

module.exports = {
  solidity: "0.8.17",
  networks: {
    goerli: {
      url: "https://eth-goerli.g.alchemy.com/v2/Y1a76FQy1tAbHFLHdG4q7_xQYWf5u7m1",
      accounts: [
        "4c905f7320e4e8f12d173716cbb485983c1e6ba3c55423d32b91842845a1247c",
      ],
    },
  },
};
