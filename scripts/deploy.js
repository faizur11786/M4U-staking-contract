// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  const accounts = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", accounts[0].address);

  const MokeToken = await hre.ethers.getContractFactory("MokeToken");
  const mokeToken = await MokeToken.deploy("Moke Token", "MOKE");
  //   await mokeToken.deployed();

  console.log("MokeToken Address: ", mokeToken.address);
  const DropBonus = await hre.ethers.getContractFactory("DropBonus");
  const dropDonus = await DropBonus.deploy(
    accounts[0].address,
    mokeToken.address
  );
  //   await dropDonus.deployed();

  return {
    mokeToken,
    dropDonus,
  };
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}

exports.deploy = main;
