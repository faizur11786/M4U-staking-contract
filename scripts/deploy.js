const hre = require("hardhat");
const { mkdirSync } = require("fs");
const { createAbiJSON } = require("../utils");

async function deploy(name, ...params) {
  mkdirSync("abi", { recursive: true });
  const Contract = await hre.ethers.getContractFactory(name);
  return await Contract.deploy(...params).then((con) => {
    createAbiJSON(con, name);
    return con.deployed();
  });
}

async function main() {
  mkdirSync("abi", { recursive: true });

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

  console.log("Approving DropBonus to spend 1000 Token");

  const tx = await token.approve(
    dropDonus.address,
    ethers.utils.parseEther("10000")
  );
  await tx.wait();

  console.log("Done.");

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
module.exports = {
  deploy,
};
