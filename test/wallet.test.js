const { expect } = require("chai");
const { deploy } = require("../scripts/deploy");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

describe("Running Test...", async () => {
  async function deployOneYearLockFixture() {
    const [owner, signer, relay] = await ethers.getSigners();
    const provider = ethers.provider;
    const tokenPayer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

    const wallet = await deploy(
      "Wallet",
      "0x675bE6d0B35117D21C538d3363C5DB7699658157",
      "0x06091113515eEB02C0b159c24b1f6c62075BF7eB"
    );
    await wallet.deployTransaction.wait();
    const ERC_20_ABI = [
      {
        constant: true,
        inputs: [],
        name: "name",
        outputs: [{ name: "", type: "string" }],
        payable: false,
        stateMutability: "view",
        type: "function",
      },
      {
        constant: false,
        inputs: [
          { name: "_spender", type: "address" },
          { name: "_value", type: "uint256" },
        ],
        name: "approve",
        outputs: [{ name: "", type: "bool" }],
        payable: false,
        stateMutability: "nonpayable",
        type: "function",
      },
      {
        constant: true,
        inputs: [],
        name: "totalSupply",
        outputs: [{ name: "", type: "uint256" }],
        payable: false,
        stateMutability: "view",
        type: "function",
      },
      {
        constant: false,
        inputs: [
          { name: "_from", type: "address" },
          { name: "_to", type: "address" },
          { name: "_value", type: "uint256" },
        ],
        name: "transferFrom",
        outputs: [{ name: "", type: "bool" }],
        payable: false,
        stateMutability: "nonpayable",
        type: "function",
      },
      {
        constant: true,
        inputs: [],
        name: "decimals",
        outputs: [{ name: "", type: "uint8" }],
        payable: false,
        stateMutability: "view",
        type: "function",
      },
      {
        constant: true,
        inputs: [{ name: "_owner", type: "address" }],
        name: "balanceOf",
        outputs: [{ name: "balance", type: "uint256" }],
        payable: false,
        stateMutability: "view",
        type: "function",
      },
      {
        constant: true,
        inputs: [],
        name: "symbol",
        outputs: [{ name: "", type: "string" }],
        payable: false,
        stateMutability: "view",
        type: "function",
      },
      {
        constant: false,
        inputs: [
          { name: "_to", type: "address" },
          { name: "_value", type: "uint256" },
        ],
        name: "transfer",
        outputs: [{ name: "", type: "bool" }],
        payable: false,
        stateMutability: "nonpayable",
        type: "function",
      },
      {
        constant: true,
        inputs: [
          { name: "_owner", type: "address" },
          { name: "_spender", type: "address" },
        ],
        name: "allowance",
        outputs: [{ name: "", type: "uint256" }],
        payable: false,
        stateMutability: "view",
        type: "function",
      },
      { payable: true, stateMutability: "payable", type: "fallback" },
      {
        anonymous: false,
        inputs: [
          { indexed: true, name: "owner", type: "address" },
          { indexed: true, name: "spender", type: "address" },
          { indexed: false, name: "value", type: "uint256" },
        ],
        name: "Approval",
        type: "event",
      },
      {
        anonymous: false,
        inputs: [
          { indexed: true, name: "from", type: "address" },
          { indexed: true, name: "to", type: "address" },
          { indexed: false, name: "value", type: "uint256" },
        ],
        name: "Transfer",
        type: "event",
      },
    ];

    const tokenA = new ethers.Contract(
      "0x564c4C6FA8994f3f4C1eE9e61193cc093cdb98Fe",
      ERC_20_ABI,
      tokenPayer
    );

    const tokenB = new ethers.Contract(
      "0x55d398326f99059ff775485246999027b3197955",
      ERC_20_ABI,
      tokenPayer
    );

    return { owner, signer, relay, tokenPayer, wallet, tokenA, tokenB };
  }
  it("Should Token Payer has enough balance to pay for Add Liquidity", async () => {
    const { tokenA, tokenB, tokenPayer } = await loadFixture(
      deployOneYearLockFixture
    );
    expect(Number(await tokenA.balanceOf(tokenPayer.address))).greaterThan(
      100 * 1e18
    );
    expect(Number(await tokenB.balanceOf(tokenPayer.address))).greaterThan(
      1 * 1e18
    );
  });

  it("Should Deposit 1 token into wallet", async () => {
    const { wallet, tokenA, tokenB, tokenPayer } = await loadFixture(
      deployOneYearLockFixture
    );
    const tokenA_balance = await tokenA.balanceOf(tokenPayer.address);
    const amount = (1 * 1e18).toString();
    const apTxA = await tokenA.approve(wallet.address, amount);
    await apTxA.wait();
    const apTxB = await tokenB.approve(wallet.address, amount);
    await apTxB.wait();

    const tx = await wallet.deposit(tokenPayer.address, tokenB.address, amount);
    const recepit = await tx.wait();
    recepit.events.forEach((event) => {
      if (event.args) {
        Object.entries(event.args).forEach(([key, value]) => {
          if (isNaN(key)) {
            console.log(`${key}      ==>      ${value}`);
          }
        });
      }
    });

    expect(Number(tokenA_balance) / 1e18).greaterThan(
      Number(await tokenA.balanceOf(tokenPayer.address)) / 1e18
    );
  });
});
