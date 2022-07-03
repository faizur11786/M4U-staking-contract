/* eslint-disable no-unused-expressions */
const { expect } = require("chai");
// const { ethers } = require("hardhat");
const { deploy } = require("../scripts/deploy");

describe("Greeter", function () {
  it("Should deploy the contracts", async function () {
    const deployReturns = await deploy();
    expect(deployReturns.referral).to.not.be.NaN;
  });
});
