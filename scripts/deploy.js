// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  const accounts = await hre.ethers.getSigners();

  let tokenAddress, token, tokenPayer;

  if (hre.network.name === "hardhat") {
    console.log("Deploying hardhat MockToken...");
    const MokeToken = await hre.ethers.getContractFactory("MokeToken");
    token = await MokeToken.deploy("Moke Token", "MOKE");
    await token.deployed();
    tokenAddress = token.address;
    tokenPayer = accounts[0].address;
  } else {
    tokenPayer = process.env.TOKENPAYER;
    tokenAddress = process.env.TOKEN;
  }

  console.log("TOKENPAYER:", tokenPayer);
  console.log("TOKEN", tokenAddress);

  const DropBonus = await hre.ethers.getContractFactory("DropBonus");
  const dropDonus = await DropBonus.deploy(tokenPayer, tokenAddress);
  await dropDonus.deployed();

  console.log("DropBonus deployed to:", dropDonus.address);

  return {
    mokeToken: token,
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
