// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  const accounts = await hre.ethers.getSigners();

  // Dpeloying referal cobntract
  console.log("\nDeploying Referral");
  console.log("Procuring artifacts");
  const Referral = await hre.ethers.getContractFactory("Referral");
  console.log("Sending transaction");
  const referral = await Referral.deploy(
    [5, 3, 2],
    "0xc2132d05d31c914a87c6611c10748aeb04b58e8f",
    accounts[0].address
  );
  console.log("Transaction sent");
  console.log("Waiting for deployment");
  await referral.deployed();
  console.log("Waiting for block confirmation");
  await referral.deployTransaction.wait();
  console.log("Transaction confirmed");

  // Deploying pool factory
  console.log("\nDeploying Referral");
  console.log("Procuring artifacts");
  const PoolFactory = await hre.ethers.getContractFactory("PoolFactory");
  console.log("Sending transaction");
  const poolFactory = await PoolFactory.deploy(
    "0xaE204EE82E60829A5850FE291C10bF657AF1CF02",
    accounts[0].address,
    referral.address
  );
  console.log("Transaction sent");
  console.log("Waiting for deployment");
  await poolFactory.deployed();
  console.log("Waiting for block confirmation");
  await poolFactory.deployTransaction.wait();
  console.log("Transaction confirmed");
  return {
    referral: referral.address,
    poolFactory: poolFactory.address,
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
