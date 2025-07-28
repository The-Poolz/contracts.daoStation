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

    // Deploy mock Universal Router with WETH address
    const MockUniversalRouter = await ethers.getContractFactory("MockUniversalRouter");
    const router = await MockUniversalRouter.deploy(await weth.getAddress(), ethers.ZeroAddress);
    await router.waitForDeployment();

    const TreasuryManagerTest = await ethers.getContractFactory("TreasuryManagerTest");
    treasuryTest = await TreasuryManagerTest.deploy(await router.getAddress(), await weth.getAddress());
    await treasuryTest.waitForDeployment();
  });

  describe("Default Fee Configuration", function () {
    it("should have default 0.01 ETH fees", async function () {
      expect(await treasuryTest.maintainerFeeWei()).to.equal(ethers.parseEther("0.01"));
      expect(await treasuryTest.treasuryFeeWei()).to.equal(ethers.parseEther("0.01"));
    });

    it("should distribute ETH with default fees correctly", async function () {
      const ethAmount = ethers.parseEther("1.0");
      await treasuryTest.test_depositETH({ value: ethAmount });
      
      const userInitialBalance = await ethers.provider.getBalance(user.address);
      const ownerInitialBalance = await ethers.provider.getBalance(owner.address);
      
      // Call from owner account - maintainer fee will go to msg.sender (owner)
      const tx = await treasuryTest.test_distributeETH(ethAmount, user.address);
      const receipt = await tx.wait();
      const gasUsed = receipt.gasUsed * receipt.gasPrice;
      
      const userFinalBalance = await ethers.provider.getBalance(user.address);
      const ownerFinalBalance = await ethers.provider.getBalance(owner.address);
      
      // With 0.01 ETH static fees each:
      // Maintainer: 0.01 ETH
      // Treasury: 0.01 ETH
      // User: 1 ETH - 0.01 - 0.01 = 0.98 ETH
      expect(userFinalBalance - userInitialBalance).to.equal(ethers.parseEther("0.98"));
      // Owner gets maintainer fee minus gas costs
      expect(ownerFinalBalance - ownerInitialBalance + gasUsed).to.equal(ethers.parseEther("0.01"));
      expect(await treasuryTest.getTreasuryBalance()).to.equal(ethers.parseEther("0.01"));
    });
  });

  describe("Fee Configuration Management", function () {
    it("should allow owner to set new fee amounts", async function () {
      // Set 0.005 ETH maintainer fee and 0.02 ETH treasury fee
      const maintainerFee = ethers.parseEther("0.005");
      const treasuryFee = ethers.parseEther("0.02");
      
      await expect(treasuryTest.connect(owner).setFees(maintainerFee, treasuryFee))
        .to.emit(treasuryTest, "FeeUpdated")
        .withArgs(maintainerFee, treasuryFee);
      
      expect(await treasuryTest.maintainerFeeWei()).to.equal(maintainerFee);
      expect(await treasuryTest.treasuryFeeWei()).to.equal(treasuryFee);
    });

    it("should reject fee amounts above maximum", async function () {
      const MAX_FEE = ethers.parseEther("0.1"); // 0.1 ETH
      const OVER_MAX_FEE = ethers.parseEther("0.11"); // 0.11 ETH
      
      await expect(treasuryTest.connect(owner).setFees(OVER_MAX_FEE, ethers.parseEther("0.01")))
        .to.be.revertedWithCustomError(treasuryTest, "MaintainerFeeTooHigh");
      
      await expect(treasuryTest.connect(owner).setFees(ethers.parseEther("0.01"), OVER_MAX_FEE))
        .to.be.revertedWithCustomError(treasuryTest, "TreasuryFeeTooHigh");
    });

    it("should allow setting maximum fees", async function () {
      const MAX_FEE = ethers.parseEther("0.1"); // 0.1 ETH
      
      await expect(treasuryTest.connect(owner).setFees(MAX_FEE, MAX_FEE))
        .to.emit(treasuryTest, "FeeUpdated")
        .withArgs(MAX_FEE, MAX_FEE);
      
      expect(await treasuryTest.maintainerFeeWei()).to.equal(MAX_FEE);
      expect(await treasuryTest.treasuryFeeWei()).to.equal(MAX_FEE);
    });

    it("should allow setting zero fees", async function () {
      await expect(treasuryTest.connect(owner).setFees(0, 0))
        .to.emit(treasuryTest, "FeeUpdated")
        .withArgs(0, 0);
      
      expect(await treasuryTest.maintainerFeeWei()).to.equal(0);
      expect(await treasuryTest.treasuryFeeWei()).to.equal(0);
    });

    it("should reject non-owner attempting to set fees", async function () {
      await expect(treasuryTest.connect(nonOwner).setFees(ethers.parseEther("0.005"), ethers.parseEther("0.02")))
        .to.be.revertedWithCustomError(treasuryTest, "OwnableUnauthorizedAccount")
        .withArgs(nonOwner.address);
    });
  });

  describe("Custom Fee Distribution", function () {
    it("should distribute ETH with custom fees correctly", async function () {
      // Set 0.005 ETH maintainer fee and 0.02 ETH treasury fee
      const maintainerFee = ethers.parseEther("0.005");
      const treasuryFee = ethers.parseEther("0.02");
      await treasuryTest.connect(owner).setFees(maintainerFee, treasuryFee);
      
      const ethAmount = ethers.parseEther("1.0");
      await treasuryTest.test_depositETH({ value: ethAmount });
      
      const userInitialBalance = await ethers.provider.getBalance(user.address);
      const ownerInitialBalance = await ethers.provider.getBalance(owner.address);
      
      // Call from owner account - maintainer fee will go to msg.sender (owner)
      const tx = await treasuryTest.test_distributeETH(ethAmount, user.address);
      const receipt = await tx.wait();
      const gasUsed = receipt.gasUsed * receipt.gasPrice;
      
      const userFinalBalance = await ethers.provider.getBalance(user.address);
      const ownerFinalBalance = await ethers.provider.getBalance(owner.address);
      
      // With 0.005 ETH maintainer and 0.02 ETH treasury:
      // Maintainer: 0.005 ETH
      // Treasury: 0.02 ETH
      // User: 1 ETH - 0.005 - 0.02 = 0.975 ETH
      expect(userFinalBalance - userInitialBalance).to.equal(ethers.parseEther("0.975"));
      // Owner gets maintainer fee minus gas costs
      expect(ownerFinalBalance - ownerInitialBalance + gasUsed).to.equal(maintainerFee);
      expect(await treasuryTest.getTreasuryBalance()).to.equal(treasuryFee);
    });

    it("should handle zero fees correctly", async function () {
      // Set zero fees
      await treasuryTest.connect(owner).setFees(0, 0);
      
      const ethAmount = ethers.parseEther("1.0");
      await treasuryTest.test_depositETH({ value: ethAmount });
      
      const userInitialBalance = await ethers.provider.getBalance(user.address);
      const ownerInitialBalance = await ethers.provider.getBalance(owner.address);
      
      // Call from owner account - maintainer fee will go to msg.sender (owner)
      const tx = await treasuryTest.test_distributeETH(ethAmount, user.address);
      const receipt = await tx.wait();
      const gasUsed = receipt.gasUsed * receipt.gasPrice;
      
      const userFinalBalance = await ethers.provider.getBalance(user.address);
      const ownerFinalBalance = await ethers.provider.getBalance(owner.address);
      
      // With zero fees, user should get all ETH
      expect(userFinalBalance - userInitialBalance).to.equal(ethers.parseEther("1.0"));
      // Owner gets no maintainer fee (0) minus gas costs
      expect(ownerFinalBalance - ownerInitialBalance + gasUsed).to.equal(ethers.parseEther("0"));
      expect(await treasuryTest.getTreasuryBalance()).to.equal(ethers.parseEther("0"));
    });

    it("should handle maximum fees correctly", async function () {
      // Set maximum fees (0.1 ETH each)
      const MAX_FEE = ethers.parseEther("0.1");
      await treasuryTest.connect(owner).setFees(MAX_FEE, MAX_FEE);
      
      const ethAmount = ethers.parseEther("1.0");
      await treasuryTest.test_depositETH({ value: ethAmount });
      
      const userInitialBalance = await ethers.provider.getBalance(user.address);
      const ownerInitialBalance = await ethers.provider.getBalance(owner.address);
      
      // Call from owner account - maintainer fee will go to msg.sender (owner)
      const tx = await treasuryTest.test_distributeETH(ethAmount, user.address);
      const receipt = await tx.wait();
      const gasUsed = receipt.gasUsed * receipt.gasPrice;
      
      const userFinalBalance = await ethers.provider.getBalance(user.address);
      const ownerFinalBalance = await ethers.provider.getBalance(owner.address);
      
      // With 0.1 ETH fees each:
      // Maintainer: 0.1 ETH
      // Treasury: 0.1 ETH
      // User: 1 ETH - 0.1 - 0.1 = 0.8 ETH
      expect(userFinalBalance - userInitialBalance).to.equal(ethers.parseEther("0.8"));
      // Owner gets maintainer fee minus gas costs
      expect(ownerFinalBalance - ownerInitialBalance + gasUsed).to.equal(MAX_FEE);
      expect(await treasuryTest.getTreasuryBalance()).to.equal(MAX_FEE);
    });

    it("should revert when ETH balance is insufficient to cover fees", async function () {
      // Set fees higher than available ETH
      const highFee = ethers.parseEther("0.1"); // 0.1 ETH each
      await treasuryTest.connect(owner).setFees(highFee, highFee);

      const ethAmount = ethers.parseEther("0.1"); // Only 0.1 ETH available, but fees require 0.2 ETH
      await treasuryTest.test_depositETH({ value: ethAmount });
      
      // Should revert with InsufficientBalance
      await expect(treasuryTest.test_distributeETH(ethAmount, user.address))
        .to.be.revertedWithCustomError(treasuryTest, "InsufficientBalance");
    });
  });

  describe("Fee Constants", function () {
    it("should have correct MAX_FEE_WEI constant", async function () {
      expect(await treasuryTest.MAX_FEE_WEI()).to.equal(ethers.parseEther("0.1")); // 0.1 ETH
    });
  });
});