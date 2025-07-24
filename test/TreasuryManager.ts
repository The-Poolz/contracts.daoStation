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

    // Deploy mock Universal Router with WETH address
    const MockUniversalRouter = await ethers.getContractFactory("MockUniversalRouter");
    const router = await MockUniversalRouter.deploy(await weth.getAddress());
    await router.waitForDeployment();

    const TreasuryManagerTest = await ethers.getContractFactory("TreasuryManagerTest");
    treasuryTest = await TreasuryManagerTest.deploy(await router.getAddress(), await weth.getAddress(), owner.address);
    await treasuryTest.waitForDeployment();
  });

  it("should distribute ETH correctly", async function () {
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
    
    expect(userFinalBalance - userInitialBalance).to.equal(ethers.parseEther("0.97"));
    // Owner gets maintainer fee minus gas costs
    expect(ownerFinalBalance - ownerInitialBalance + gasUsed).to.equal(ethers.parseEther("0.015"));
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
