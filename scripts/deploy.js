// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  const MokeToken = await hre.ethers.getContractFactory("MokeToken");

  console.log("Deploying X MokeToken...");
  const xToken = await MokeToken.deploy("X Token", "XT");
  await xToken.deployed();
  console.log("X Token address:", xToken.address);

  console.log("Deploying USDT MokeToken...");
  const usdt = await MokeToken.deploy("USD Token", "USDT");
  await usdt.deployed();
  console.log("USD Token address:", usdt.address);

  //   const PoolFactory = await hre.ethers.getContractFactory("PoolFactory");
  //   const poolFactory = await PoolFactory.deploy();

  //   await poolFactory.deployed();

  //   console.log("Greeter deployed to:", poolFactory.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
