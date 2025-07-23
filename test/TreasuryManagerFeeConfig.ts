const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("TreasuryManager Fee Configuration", function () {
  let owner: any, user: any, maintainer: any, nonOwner: any;
  let treasuryTest: any;

  beforeEach(async function () {
    const signers = await ethers.getSigners();
    [owner, user, maintainer, nonOwner] = signers;

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

  describe("Default Fee Configuration", function () {
    it("should have default 1.5% fees (150 basis points)", async function () {
      expect(await treasuryTest.maintainerFeePercent()).to.equal(150);
      expect(await treasuryTest.treasuryFeePercent()).to.equal(150);
    });

    it("should distribute ETH with default fees correctly", async function () {
      const ethAmount = ethers.parseEther("1.0");
      await treasuryTest.test_depositETH({ value: ethAmount });
      
      const userInitialBalance = await ethers.provider.getBalance(user.address);
      const maintainerInitialBalance = await ethers.provider.getBalance(maintainer.address);
      
      await treasuryTest.test_distributeETH(ethAmount, user.address, maintainer.address);
      
      const userFinalBalance = await ethers.provider.getBalance(user.address);
      const maintainerFinalBalance = await ethers.provider.getBalance(maintainer.address);
      
      // With 150 basis points (1.5%) each:
      // Maintainer: 1 ETH * 150 / 10000 = 0.015 ETH
      // Treasury: 1 ETH * 150 / 10000 = 0.015 ETH
      // User: 1 ETH - 0.015 - 0.015 = 0.97 ETH
      expect(userFinalBalance - userInitialBalance).to.equal(ethers.parseEther("0.97"));
      expect(maintainerFinalBalance - maintainerInitialBalance).to.equal(ethers.parseEther("0.015"));
      expect(await treasuryTest.getTreasuryBalance()).to.equal(ethers.parseEther("0.015"));
    });
  });

  describe("Fee Configuration Management", function () {
    it("should allow owner to set new fee percentages", async function () {
      // Set 1% maintainer fee (100 basis points) and 2% treasury fee (200 basis points)
      await expect(treasuryTest.connect(owner).setFeePercents(100, 200))
        .to.emit(treasuryTest, "FeeUpdated")
        .withArgs(100, 200);
      
      expect(await treasuryTest.maintainerFeePercent()).to.equal(100);
      expect(await treasuryTest.treasuryFeePercent()).to.equal(200);
    });

    it("should reject fee percentages above maximum", async function () {
      const MAX_FEE = 500; // 5%
      
      await expect(treasuryTest.connect(owner).setFeePercents(501, 200))
        .to.be.revertedWithCustomError(treasuryTest, "MaintainerFeeTooHigh");
      
      await expect(treasuryTest.connect(owner).setFeePercents(200, 501))
        .to.be.revertedWithCustomError(treasuryTest, "TreasuryFeeTooHigh");
    });

    it("should allow setting maximum fees", async function () {
      const MAX_FEE = 500; // 5%
      
      await expect(treasuryTest.connect(owner).setFeePercents(MAX_FEE, MAX_FEE))
        .to.emit(treasuryTest, "FeeUpdated")
        .withArgs(MAX_FEE, MAX_FEE);
      
      expect(await treasuryTest.maintainerFeePercent()).to.equal(MAX_FEE);
      expect(await treasuryTest.treasuryFeePercent()).to.equal(MAX_FEE);
    });

    it("should allow setting zero fees", async function () {
      await expect(treasuryTest.connect(owner).setFeePercents(0, 0))
        .to.emit(treasuryTest, "FeeUpdated")
        .withArgs(0, 0);
      
      expect(await treasuryTest.maintainerFeePercent()).to.equal(0);
      expect(await treasuryTest.treasuryFeePercent()).to.equal(0);
    });

    it("should reject non-owner attempting to set fees", async function () {
      await expect(treasuryTest.connect(nonOwner).setFeePercents(100, 200))
        .to.be.revertedWithCustomError(treasuryTest, "OwnableUnauthorizedAccount")
        .withArgs(nonOwner.address);
    });
  });

  describe("Custom Fee Distribution", function () {
    it("should distribute ETH with custom fees correctly", async function () {
      // Set 1% maintainer fee and 2% treasury fee
      await treasuryTest.connect(owner).setFeePercents(100, 200);
      
      const ethAmount = ethers.parseEther("1.0");
      await treasuryTest.test_depositETH({ value: ethAmount });
      
      const userInitialBalance = await ethers.provider.getBalance(user.address);
      const maintainerInitialBalance = await ethers.provider.getBalance(maintainer.address);
      
      await treasuryTest.test_distributeETH(ethAmount, user.address, maintainer.address);
      
      const userFinalBalance = await ethers.provider.getBalance(user.address);
      const maintainerFinalBalance = await ethers.provider.getBalance(maintainer.address);
      
      // With 100 basis points (1%) maintainer and 200 basis points (2%) treasury:
      // Maintainer: 1 ETH * 100 / 10000 = 0.01 ETH
      // Treasury: 1 ETH * 200 / 10000 = 0.02 ETH
      // User: 1 ETH - 0.01 - 0.02 = 0.97 ETH
      expect(userFinalBalance - userInitialBalance).to.equal(ethers.parseEther("0.97"));
      expect(maintainerFinalBalance - maintainerInitialBalance).to.equal(ethers.parseEther("0.01"));
      expect(await treasuryTest.getTreasuryBalance()).to.equal(ethers.parseEther("0.02"));
    });

    it("should handle zero fees correctly", async function () {
      // Set zero fees
      await treasuryTest.connect(owner).setFeePercents(0, 0);
      
      const ethAmount = ethers.parseEther("1.0");
      await treasuryTest.test_depositETH({ value: ethAmount });
      
      const userInitialBalance = await ethers.provider.getBalance(user.address);
      const maintainerInitialBalance = await ethers.provider.getBalance(maintainer.address);
      
      await treasuryTest.test_distributeETH(ethAmount, user.address, maintainer.address);
      
      const userFinalBalance = await ethers.provider.getBalance(user.address);
      const maintainerFinalBalance = await ethers.provider.getBalance(maintainer.address);
      
      // With zero fees, user should get all ETH
      expect(userFinalBalance - userInitialBalance).to.equal(ethers.parseEther("1.0"));
      expect(maintainerFinalBalance - maintainerInitialBalance).to.equal(ethers.parseEther("0"));
      expect(await treasuryTest.getTreasuryBalance()).to.equal(ethers.parseEther("0"));
    });

    it("should handle maximum fees correctly", async function () {
      // Set maximum fees (5% each)
      const MAX_FEE = 500;
      await treasuryTest.connect(owner).setFeePercents(MAX_FEE, MAX_FEE);
      
      const ethAmount = ethers.parseEther("1.0");
      await treasuryTest.test_depositETH({ value: ethAmount });
      
      const userInitialBalance = await ethers.provider.getBalance(user.address);
      const maintainerInitialBalance = await ethers.provider.getBalance(maintainer.address);
      
      await treasuryTest.test_distributeETH(ethAmount, user.address, maintainer.address);
      
      const userFinalBalance = await ethers.provider.getBalance(user.address);
      const maintainerFinalBalance = await ethers.provider.getBalance(maintainer.address);
      
      // With 500 basis points (5%) each:
      // Maintainer: 1 ETH * 500 / 10000 = 0.05 ETH
      // Treasury: 1 ETH * 500 / 10000 = 0.05 ETH
      // User: 1 ETH - 0.05 - 0.05 = 0.9 ETH
      expect(userFinalBalance - userInitialBalance).to.equal(ethers.parseEther("0.9"));
      expect(maintainerFinalBalance - maintainerInitialBalance).to.equal(ethers.parseEther("0.05"));
      expect(await treasuryTest.getTreasuryBalance()).to.equal(ethers.parseEther("0.05"));
    });
  });

  describe("Fee Constants", function () {
    it("should have correct MAX_FEE_PERCENT constant", async function () {
      expect(await treasuryTest.MAX_FEE_PERCENT()).to.equal(500); // 5%
    });
  });
});