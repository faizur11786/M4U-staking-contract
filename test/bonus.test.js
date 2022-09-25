/* eslint-disable no-unused-expressions */
const { expect } = require("chai");
// const { ethers } = require("hardhat");
const { deploy } = require("../scripts/deploy");
// We use `loadFixture` to share common setups (or fixtures) between tests.
// Using this simplifies your tests and makes them run faster, by taking
// advantage of Hardhat Network's snapshot functionality.
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { ethers } = require("hardhat");

describe("Running...", async function () {
  async function deployTokenFixture() {
    const { mokeToken, dropDonus } = await deploy();
    const [owner, addr1, addr2, addr3] = await ethers.getSigners();
    // Fixtures can return anything you consider useful for your tests
    return { mokeToken, dropDonus, owner, addr1, addr2, addr3 };
  }

  it("Should deploy the contracts", async function () {
    const { mokeToken, dropDonus, owner } = await loadFixture(
      deployTokenFixture
    );
    expect(await mokeToken.totalSupply()).to.equal(
      await mokeToken.balanceOf(owner.address)
    );
    expect(await dropDonus.tokenPayer()).to.equal(owner.address);
    expect(await dropDonus.owner()).to.equal(owner.address);
  });
  it("Should Approve the DropBonus Contract", async () => {
    const { mokeToken, dropDonus, owner } = await loadFixture(
      deployTokenFixture
    );
    const amount = ethers.utils.parseEther("1000");
    const tx = await mokeToken.approve(dropDonus.address, amount);
    await tx.wait();
    const allowance = await mokeToken.allowance(
      owner.address,
      dropDonus.address
    );
    expect(allowance).to.equal(amount);
  });

  it("Should transfer 10 bonus token to Address1", async () => {
    const { dropDonus, mokeToken, addr1 } = await loadFixture(
      deployTokenFixture
    );
    const amount = ethers.utils.parseEther("10");
    const tx = await dropDonus.sandBonus(addr1.address, amount);
    await tx.wait();
    expect(await mokeToken.balanceOf(addr1.address)).to.equal(amount);
  });

  it("Should 10 Token in bonusAmountOf mapping", async () => {
    const { dropDonus, addr1 } = await loadFixture(deployTokenFixture);
    const amount = ethers.utils.parseEther("10");
    expect(await dropDonus.bonusAmountOf(addr1.address)).to.equal(amount);
  });
});
