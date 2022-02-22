// Load dependencies
const Web3 = require("web3")

require('chai')
    .use(require('chai-as-promised'))
    .should()
const { assert } = require("chai");

const PokeBall = artifacts.require("PokeBall");
const PokeBallNFT = artifacts.require("PokeBallNFT");
const PokeNFTMarketplace = artifacts.require('PokeNFTMarketplace');

const FeeReceiptant = '0xD2aBb7ca32B28ef6D7bcA0d5C00f9A022ccad2d7';
const TEST_OWNER = '0xD2aBb7ca32B28ef6D7bcA0d5C00f9A022ccad2d7';
const TEST2_OWNER = '0x43e2cF040AE1a266C0B91278e4C20671191699eb';

contract("POKE", function () {
    let web3 = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:8545'))

    let pokeball;
    let pokenft;
    let pokemarket;
    it("should assert true", async function () {
      pokeball = await PokeBall.deployed();
      pokenft = await PokeBallNFT.deployed();
      pokemarket = await PokeNFTMarketplace.deployed();

      return assert.isTrue(true);
    });
  
    describe("Ball", async () => {

      it("check balance after mint BEP20 while deploying", async () => {
        assert.equal((await pokeball.balanceOf(TEST_OWNER)).toString(), '1000000000000000000', "Balance is not match");
      })

      it("check transfer fee", async () => {
        await pokeball.transfer(TEST2_OWNER, "10000000000", { from : TEST_OWNER});
        assert.equal((await pokeball.balanceOf(TEST2_OWNER)).toString(), '9500000000', "Balance is not correct");
        assert.equal((await pokeball.balanceOf(TEST_OWNER)).toString(), '999999990500000000', "Balance is not correct");

      })
  
      it("create nft", async () => {
        // unregistered category should be rejected
        await pokenft.spawn("hash_1", "Name 1", "1000000000", {from: TEST2_OWNER}).should.be.rejected
        await pokenft.spawn("hash_1", "Name 1", "100000000", {from: TEST_OWNER}).should.be.rejected
        await pokenft.spawn("hash_1", "Name 1", "1000000000", {from: TEST_OWNER})

      });

      it("Buy nft", async () => {
        // should be reject cuz market is not open to sale  
        await pokenft.multiMint(TEST_OWNER, 1, 3, "3000000000", {from: TEST_OWNER}).should.be.rejected
        // open market
        await pokenft.pause(false, {from: TEST_OWNER});

        await pokeball.approve(pokenft.address, "2000000000", {from: TEST2_OWNER});
        await pokenft.multiMint(TEST2_OWNER, 1, 2, "2000000000", {from: TEST2_OWNER})

        // not allowance
        await pokenft.multiMint(TEST_OWNER, 1, 3, "3000000000", {from: TEST_OWNER}).should.be.rejected
        await pokeball.approve(pokenft.address, "3000000000", {from: TEST_OWNER});
        // not enough to buy
        await pokenft.multiMint(TEST_OWNER, 1, 3, "2000000000", {from: TEST_OWNER}).should.be.rejected
        await pokenft.multiMint(TEST_OWNER, 1, 3, "3000000000", {from: TEST_OWNER})

        assert.equal((await pokenft.balanceOf(TEST_OWNER)).toString(), '3', "Balance is not match");
        assert.equal((await pokenft.balanceOf(TEST2_OWNER)).toString(), '2', "Balance is not match");
        assert.equal((await pokenft.totalSupply()).toString(), '5', "Total Supply is not match");

        // balance check
        assert.equal((await pokeball.balanceOf(pokenft.address)).toString(), '4750000000', "Balance is not correct");

      });

      it("transfer ownership works", async () => {
        await pokeball.transferOwnership(TEST2_OWNER);
        const new1_owner = (await pokeball.owner()).toString();
        assert.equal(new1_owner, TEST2_OWNER, "Owner pokeball doesnot match");

        
        await pokenft.transferOwnership(TEST2_OWNER);
        const new2_owner = (await pokenft.owner()).toString();
        assert.equal(new2_owner, TEST2_OWNER, "Owner pokenft doesnot match");

        
        await pokemarket.transferOwnership(TEST2_OWNER);
        const new3_owner = (await pokemarket.owner()).toString();
        assert.equal(new3_owner, TEST2_OWNER, "Owner pokemarket doesnot match");
      });
    });
});