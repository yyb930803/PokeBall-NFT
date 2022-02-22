const HDWalletProvider = require('@truffle/hdwallet-provider');
require('dotenv').config();
// const fs = require('fs');
// const mnemonic = fs.readFileSync(".secret").toString().trim();

const RINKEBY_DEPLOYER_KEY = process.env.RINKEBY_DEPLOYER_KEY;
const BSC_DEPLOYER_KEY = process.env.BSC_DEPLOYER_KEY;
const BSC_TESTNET_DEPLOYER_KEY = process.env.BSC_TESTNET_DEPLOYER_KEY;

const NODES = [
  'https://data-seed-prebsc-1-s1.binance.org:8545/',
  'https://data-seed-prebsc-2-s1.binance.org:8545/',
  'https://data-seed-prebsc-2-s2.binance.org:8545/',
  'https://data-seed-prebsc-1-s3.binance.org:8545/',
  'https://data-seed-prebsc-2-s3.binance.org:8545/'
]

const rnd = Math.floor(Math.random() * NODES.length);
const rpc_node = NODES[rnd];
console.log("RPC", rnd, rpc_node);

module.exports = {
  /**
   * Networks define how you connect to your ethereum client and let you set the
   * defaults web3 uses to send transactions. If you don't specify one truffle
   * will spin up a development blockchain for you on port 9545 when you
   * run `develop` or `test`. You can ask a truffle command to use a specific
   * network from the command line, e.g
   *
   * $ truffle test --network <network-name>
   */

  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
    },
    rinkeby: {
      provider: () => new HDWalletProvider(RINKEBY_DEPLOYER_KEY, `https://rinkeby.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161`),
      network_id: 4,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
      networkCheckTimeout: 360000
      // from: '0x3E4e789b2FCb30AbEa420705610895D307d4F866'
    },
    ropsten: {
      provider: () => new HDWalletProvider(RINKEBY_DEPLOYER_KEY, `https://ropsten.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161`, 0, 14),
      network_id: 3,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
      networkCheckTimeout: 360000
      // from: '0x3E4e789b2FCb30AbEa420705610895D307d4F866'
    },
    goerli: {
      provider: () => new HDWalletProvider(RINKEBY_DEPLOYER_KEY, `https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161`, 0, 14),
      network_id: 5,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
      networkCheckTimeout: 360000
      // from: '0x3E4e789b2FCb30AbEa420705610895D307d4F866'
    },
    testnet: {
      provider: () => new HDWalletProvider(BSC_TESTNET_DEPLOYER_KEY, `${rpc_node}`),
      network_id: 97,
      confirmations: 5,
      timeoutBlocks: 200,
      skipDryRun: true,
      networkCheckTimeout: 360000
      // from: '0x74191c794b641744cD1066ce9025aEAa2A856823',
    },
    bsc: {
      provider: () => new HDWalletProvider(BSC_DEPLOYER_KEY, `https://bsc-dataseed.binance.org`),
      network_id: 56,
      confirmations: 5,
      timeoutBlocks: 200,
      skipDryRun: true,
      // from: '0xd3C1C1c23d9E689832C586D62Bb64620A3D7574f',
    },
  },

  plugins: [
    'truffle-plugin-verify'
  ],

  api_keys: {
    etherscan: process.env.BSCSCAN_API_KEY
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.0",    // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      settings: {          // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 200
        },
      //  evmVersion: "byzantium"
      }
    }
  },

  // Truffle DB is currently disabled by default; to enable it, change enabled:
  // false to enabled: true. The default storage location can also be
  // overridden by specifying the adapter settings, as shown in the commented code below.
  //
  // NOTE: It is not possible to migrate your contracts to truffle DB and you should
  // make a backup of your artifacts to a safe location before enabling this feature.
  //
  // After you backed up your artifacts you can utilize db by running migrate as follows: 
  // $ truffle migrate --reset --compile-all
  //
  // db: {
    // enabled: false,
    // host: "127.0.0.1",
    // adapter: {
    //   name: "sqlite",
    //   settings: {
    //     directory: ".db"
    //   }
    // }
  // }
};
