const hardhat = require("hardhat");
const { expect } = require("chai");

describe("PermitSwapExecutor Main Contract", function () {
  let owner: any, maintainer: any, user: any, treasury: any;
  let executor: any, token: any, weth: any, router: any;

  beforeEach(async function () {
    const signers = await hardhat.ethers.getSigners();
    [owner, maintainer, user, treasury] = signers;

    // Deploy mock WETH
    const MockWETH9 = await hardhat.ethers.getContractFactory("MockWETH9");
    weth = await MockWETH9.deploy();
    await weth.waitForDeployment();

    // Deploy mock ERC20 with permit
    const MockERC20Permit = await hardhat.ethers.getContractFactory("MockERC20Permit");
    token = await MockERC20Permit.deploy("MockToken", "MTK", 18);
    await token.waitForDeployment();

    // Deploy mock Uniswap V3 router
    const MockSwapRouter = await hardhat.ethers.getContractFactory("MockSwapRouterV3");
    router = await MockSwapRouter.deploy(await weth.getAddress());
    await router.waitForDeployment();

    // Deploy main PermitSwapExecutor
    const PermitSwapExecutor = await hardhat.ethers.getContractFactory("PermitSwapExecutor");
    executor = await PermitSwapExecutor.deploy(
      await router.getAddress(),
      owner.address
    );
    await executor.waitForDeployment();
  });

  describe("Contract Deployment", function () {
    it("should deploy with correct owner", async function () {
      expect(await executor.owner()).to.equal(owner.address);
    });

    it("should have correct router address", async function () {
      expect(await executor.uniswapRouter()).to.equal(await router.getAddress());
    });

    it("should have correct WETH address", async function () {
      expect(await executor.WETH()).to.equal(await weth.getAddress());
    });
  });

  describe("Maintainer Management", function () {
    it("should set maintainer as owner", async function () {
      expect(await executor.isMaintainer(maintainer.address)).to.be.false;
      
      await executor.connect(owner).setMaintainer(maintainer.address, true);
      
      expect(await executor.isMaintainer(maintainer.address)).to.be.true;
    });

    it("should emit MaintainerSet event", async function () {
      await expect(executor.connect(owner).setMaintainer(maintainer.address, true))
        .to.emit(executor, "MaintainerSet")
        .withArgs(maintainer.address, true);
    });

    it("should revert if non-owner tries to set maintainer", async function () {
      await expect(executor.connect(user).setMaintainer(maintainer.address, true))
        .to.be.revertedWithCustomError(executor, "OwnableUnauthorizedAccount");
    });
  });

  describe("ExecuteSwap Function", function () {
    beforeEach(async function () {
      // Set maintainer
      await executor.connect(owner).setMaintainer(maintainer.address, true);
      
      // Mint tokens to user
      const tokenAmount = hardhat.ethers.parseEther("1");
      await token.mint(user.address, tokenAmount);
      
      // Fund router with WETH for the swap
      const wethAmount = hardhat.ethers.parseEther("2");
      await weth.deposit({ value: wethAmount });
      await weth.transfer(await router.getAddress(), wethAmount);
    });

    it("should execute swap successfully", async function () {
      const tokenAmount = hardhat.ethers.parseEther("1");
      const deadline = Math.floor(Date.now() / 1000) + 3600;
      
      // Create permit signature
      const nonce = await token.nonces(user.address);
      const domain = {
        name: await token.name(),
        version: "1",
        chainId: 31337,
        verifyingContract: await token.getAddress()
      };
      
      const types = {
        Permit: [
          { name: "owner", type: "address" },
          { name: "spender", type: "address" },
          { name: "value", type: "uint256" },
          { name: "nonce", type: "uint256" },
          { name: "deadline", type: "uint256" }
        ]
      };
      
      const value = {
        owner: user.address,
        spender: await executor.getAddress(),
        value: tokenAmount,
        nonce: nonce,
        deadline: deadline
      };
      
      const signature = await user.signTypedData(domain, types, value);
      const { v, r, s } = hardhat.ethers.Signature.from(signature);
      
      const userInitialBalance = await hardhat.ethers.provider.getBalance(user.address);
      const maintainerInitialBalance = await hardhat.ethers.provider.getBalance(maintainer.address);
      
      // Test data to send with swap
      const testData = hardhat.ethers.toUtf8Bytes("test swap data");
      
      // Execute swap
      await expect(executor.connect(maintainer).executeSwap(
        await token.getAddress(),
        3000, // 0.3% fee
        tokenAmount,
        hardhat.ethers.parseEther("0.9"), // min out
        0, // no price limit
        user.address,
        testData,
        deadline,
        v,
        r,
        s
      )).to.emit(executor, "SwapExecuted");
      
      // Check balances
      const userFinalBalance = await hardhat.ethers.provider.getBalance(user.address);
      const maintainerFinalBalance = await hardhat.ethers.provider.getBalance(maintainer.address);
      
      // User should receive 97% of 1 ETH = 0.97 ETH
      expect(userFinalBalance - userInitialBalance).to.equal(hardhat.ethers.parseEther("0.97"));
      
      // Maintainer should receive 1.5% of 1 ETH = 0.015 ETH (approximately, accounting for gas costs)
      const maintainerGain = maintainerFinalBalance - maintainerInitialBalance;
      expect(maintainerGain).to.be.closeTo(hardhat.ethers.parseEther("0.015"), hardhat.ethers.parseEther("0.001"));
      
      // Contract should retain 1.5% as treasury = 0.015 ETH
      expect(await executor.getTreasuryBalance()).to.equal(hardhat.ethers.parseEther("0.015"));
    });

    it("should execute swap with WETH input (no swap needed)", async function () {
      const wethAmount = hardhat.ethers.parseEther("1");
      const deadline = Math.floor(Date.now() / 1000) + 3600;
      
      // Fund user with WETH
      await weth.connect(user).deposit({ value: wethAmount });
      
      // Create permit signature for WETH
      const nonce = await weth.nonces(user.address);
      const domain = {
        name: await weth.name(),
        version: "1",
        chainId: 31337,
        verifyingContract: await weth.getAddress()
      };
      
      const types = {
        Permit: [
          { name: "owner", type: "address" },
          { name: "spender", type: "address" },
          { name: "value", type: "uint256" },
          { name: "nonce", type: "uint256" },
          { name: "deadline", type: "uint256" }
        ]
      };
      
      const value = {
        owner: user.address,
        spender: await executor.getAddress(),
        value: wethAmount,
        nonce: nonce,
        deadline: deadline
      };
      
      const signature = await user.signTypedData(domain, types, value);
      const { v, r, s } = hardhat.ethers.Signature.from(signature);
      
      const userInitialBalance = await hardhat.ethers.provider.getBalance(user.address);
      const maintainerInitialBalance = await hardhat.ethers.provider.getBalance(maintainer.address);
      const treasuryInitialBalance = await executor.getTreasuryBalance();
      
      // Test data to send with swap
      const testData = hardhat.ethers.toUtf8Bytes("weth swap data");
      
      // Execute swap with WETH as input (should skip the swap step)
      await expect(executor.connect(maintainer).executeSwap(
        await weth.getAddress(), // Using WETH as input token
        3000, // Pool fee (irrelevant since no swap)
        wethAmount,
        hardhat.ethers.parseEther("0.9"), // Min out (irrelevant since no swap)
        0, // No price limit (irrelevant since no swap)
        user.address,
        testData,
        deadline,
        v,
        r,
        s
      )).to.emit(executor, "SwapExecuted");
      
      // Check balances
      const userFinalBalance = await hardhat.ethers.provider.getBalance(user.address);
      const maintainerFinalBalance = await hardhat.ethers.provider.getBalance(maintainer.address);
      const treasuryFinalBalance = await executor.getTreasuryBalance();
      
      // User should receive 97% of 1 ETH = 0.97 ETH
      expect(userFinalBalance - userInitialBalance).to.equal(hardhat.ethers.parseEther("0.97"));
      
      // Maintainer should receive 1.5% of 1 ETH = 0.015 ETH (approximately, accounting for gas costs)
      const maintainerGain = maintainerFinalBalance - maintainerInitialBalance;
      expect(maintainerGain).to.be.closeTo(hardhat.ethers.parseEther("0.015"), hardhat.ethers.parseEther("0.001"));
      
      // Contract should retain 1.5% as treasury = 0.015 ETH
      expect(treasuryFinalBalance - treasuryInitialBalance).to.equal(hardhat.ethers.parseEther("0.015"));
    });

    it("should revert if not called by maintainer", async function () {
      const tokenAmount = hardhat.ethers.parseEther("100");
      const deadline = Math.floor(Date.now() / 1000) + 3600;
      
      await expect(executor.connect(user).executeSwap(
        await token.getAddress(),
        3000,
        tokenAmount,
        hardhat.ethers.parseEther("0.9"),
        0,
        user.address,
        "0x",
        deadline,
        27,
        hardhat.ethers.ZeroHash,
        hardhat.ethers.ZeroHash
      )).to.be.revertedWithCustomError(executor, "NotMaintainer");
    });

    it("should revert if user is zero address", async function () {
      const tokenAmount = hardhat.ethers.parseEther("100");
      const deadline = Math.floor(Date.now() / 1000) + 3600;
      
      await expect(executor.connect(maintainer).executeSwap(
        await token.getAddress(),
        3000,
        tokenAmount,
        hardhat.ethers.parseEther("0.9"),
        0,
        hardhat.ethers.ZeroAddress,
        "0x",
        deadline,
        27,
        hardhat.ethers.ZeroHash,
        hardhat.ethers.ZeroHash
      )).to.be.revertedWithCustomError(executor, "ZeroUser");
    });

    it("should revert if deadline expired", async function () {
      const tokenAmount = hardhat.ethers.parseEther("100");
      const expiredDeadline = Math.floor(Date.now() / 1000) - 3600;
      
      await expect(executor.connect(maintainer).executeSwap(
        await token.getAddress(),
        3000,
        tokenAmount,
        hardhat.ethers.parseEther("0.9"),
        0,
        user.address,
        "0x",
        expiredDeadline,
        27,
        hardhat.ethers.ZeroHash,
        hardhat.ethers.ZeroHash
      )).to.be.revertedWithCustomError(executor, "Expired");
    });

    it("should revert if permit signature is not signed by user", async function () {
      const tokenAmount = hardhat.ethers.parseEther("100");
      const deadline = Math.floor(Date.now() / 1000) + 3600;
      
      // Mint tokens to user
      await token.mint(user.address, tokenAmount);
      
      // Create permit signature, but sign it with a different account (maintainer instead of user)
      const nonce = await token.nonces(user.address);
      const domain = {
        name: await token.name(),
        version: "1",
        chainId: 31337,
        verifyingContract: await token.getAddress()
      };
      
      const types = {
        Permit: [
          { name: "owner", type: "address" },
          { name: "spender", type: "address" },
          { name: "value", type: "uint256" },
          { name: "nonce", type: "uint256" },
          { name: "deadline", type: "uint256" }
        ]
      };
      
      const value = {
        owner: user.address, // Permit is for user's tokens
        spender: await executor.getAddress(),
        value: tokenAmount,
        nonce: nonce,
        deadline: deadline
      };
      
      // Sign with maintainer instead of user (this should fail)
      const signature = await maintainer.signTypedData(domain, types, value);
      const { v, r, s } = hardhat.ethers.Signature.from(signature);
      
      // This should revert because the signature doesn't match the user
      await expect(executor.connect(maintainer).executeSwap(
        await token.getAddress(),
        3000,
        tokenAmount,
        hardhat.ethers.parseEther("0.9"),
        0,
        user.address,
        "0x",
        deadline,
        v,
        r,
        s
      )).to.be.reverted;
    });
  });

  describe("Treasury Functions", function () {
    it("should allow owner to withdraw treasury", async function () {
      // Send some ETH to contract
      await owner.sendTransaction({
        to: await executor.getAddress(),
        value: hardhat.ethers.parseEther("1")
      });
      
      const treasuryInitialBalance = await hardhat.ethers.provider.getBalance(treasury.address);
      const withdrawAmount = hardhat.ethers.parseEther("0.5");
      
      await executor.connect(owner).withdrawTreasury(treasury.address, withdrawAmount);
      
      const treasuryFinalBalance = await hardhat.ethers.provider.getBalance(treasury.address);
      expect(treasuryFinalBalance - treasuryInitialBalance).to.equal(withdrawAmount);
    });
  });
});
