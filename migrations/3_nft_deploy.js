const PokeBall = artifacts.require("PokeBall");
const PokeBallNFT = artifacts.require("PokeBallNFT");

module.exports = async function (deployer)  {
    const ball = await PokeBall.deployed();
    console.log("Ball", ball.address)

    if(!ball.address) {
        console.error("something went wrong");
        return;
    }
    await deployer.deploy(PokeBallNFT, "PokeBallNFT", "PokeNFT", ball.address);
    const nft = await PokeBallNFT.deployed();
    console.log("PokeBallNFT", nft.address)
};
