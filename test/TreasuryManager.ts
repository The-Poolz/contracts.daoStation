const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("TreasuryManager", function () {
  let owner: any, user: any, maintainer: any;
  let treasuryTest: any;

  beforeEach(async function () {
    const signers = await ethers.getSigners();
    [owner, user, maintainer] = signers;

    // Deploy mock WETH
    const MockWETH9 = await ethers.getContractFactory("MockWETH9");
    const weth = await MockWETH9.deploy();
    await weth.waitForDeployment();

    // Deploy mock Uniswap V3 router
    const MockSwapRouter = await ethers.getContractFactory("MockSwapRouterV3");
    const router = await MockSwapRouter.deploy(await weth.getAddress());
    await router.waitForDeployment();

    const TreasuryManagerTest = await ethers.getContractFactory("TreasuryManagerTest");
    treasuryTest = await TreasuryManagerTest.deploy(await router.getAddress(), await weth.getAddress(), owner.address);
    await treasuryTest.waitForDeployment();
  });

  it("should distribute ETH correctly", async function () {
    const ethAmount = ethers.parseEther("1.0");
    await treasuryTest.test_depositETH({ value: ethAmount });
    
    const userInitialBalance = await ethers.provider.getBalance(user.address);
    const maintainerInitialBalance = await ethers.provider.getBalance(maintainer.address);
    
    await treasuryTest.test_distributeETH(ethAmount, user.address, maintainer.address);
    
    const userFinalBalance = await ethers.provider.getBalance(user.address);
    const maintainerFinalBalance = await ethers.provider.getBalance(maintainer.address);
    
    expect(userFinalBalance - userInitialBalance).to.equal(ethers.parseEther("0.97"));
    expect(maintainerFinalBalance - maintainerInitialBalance).to.equal(ethers.parseEther("0.015"));
  });

  it("should allow owner to withdraw treasury", async function () {
    const ethAmount = ethers.parseEther("1.0");
    await treasuryTest.test_depositETH({ value: ethAmount });
    
    const withdrawAmount = ethers.parseEther("0.5");
    await treasuryTest.connect(owner).withdrawTreasury(user.address, withdrawAmount);
    
    const balance = await treasuryTest.getTreasuryBalance();
    expect(balance).to.equal(ethAmount - withdrawAmount);
  });
});
