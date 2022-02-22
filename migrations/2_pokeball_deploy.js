const PokeBall = artifacts.require("PokeBall");

module.exports = function (deployer) {
  deployer.deploy(PokeBall, "PokeBall", "BALL");
};
