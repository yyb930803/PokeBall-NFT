const PokeBall = artifacts.require("PokeBall");
const LockedStaking = artifacts.require("LockedStaking");
module.exports = async function (deployer)  {
    const ball = await PokeBall.deployed();
    console.log("Ball", ball.address)

    if(!ball.address) {
        console.error("something went wrong");
        return;
    }
    await deployer.deploy(LockedStaking, ball.address);
    const staking = await LockedStaking.deployed();
    console.log("LockedStaking", staking.address)
};
