const hardhat = require("hardhat");
const { expect } = require("chai");

describe("PermitSwapExecutor Bytes Data", function () {
  let owner: any, maintainer: any, user: any;
  let executor: any, token: any, weth: any, router: any;

  beforeEach(async function () {
    const signers = await hardhat.ethers.getSigners();
    [owner, maintainer, user] = signers;

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

    // Set maintainer
    await executor.connect(owner).setMaintainer(maintainer.address, true);
  });

  describe("Bytes Data Functionality", function () {
    it("should emit SwapExecuted with empty bytes data", async function () {
      const tokenAmount = hardhat.ethers.parseEther("1");
      const deadline = Math.floor(Date.now() / 1000) + 3600;

      // Mint tokens to user
      await token.mint(user.address, tokenAmount);

      // Fund router with WETH for the swap
      const wethAmount = hardhat.ethers.parseEther("2");
      await weth.deposit({ value: wethAmount });
      await weth.transfer(await router.getAddress(), wethAmount);

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

      // Test with empty bytes
      const emptyData = "0x";

      await expect(executor.connect(maintainer).executeSwap(
        await token.getAddress(),
        3000,
        tokenAmount,
        hardhat.ethers.parseEther("0.9"),
        0,
        user.address,
        emptyData,
        deadline,
        v,
        r,
        s
      )).to.emit(executor, "SwapExecuted")
        .withArgs(
          user.address,
          await token.getAddress(),
          tokenAmount,
          hardhat.ethers.parseEther("1"), // 1 ETH received
          hardhat.ethers.parseEther("0.97"), // 97% to user
          hardhat.ethers.parseEther("0.015"), // 1.5% to maintainer
          hardhat.ethers.parseEther("0.015"), // 1.5% to treasury
          emptyData,
          maintainer.address
        );
    });

    it("should emit SwapExecuted with custom bytes data", async function () {
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

      // Test with complex structured data
      const customData = hardhat.ethers.toUtf8Bytes(JSON.stringify({
        swapId: "swap_123",
        metadata: "custom swap metadata",
        timestamp: Date.now()
      }));

      await expect(executor.connect(maintainer).executeSwap(
        await weth.getAddress(),
        3000,
        wethAmount,
        hardhat.ethers.parseEther("0.9"),
        0,
        user.address,
        customData,
        deadline,
        v,
        r,
        s
      )).to.emit(executor, "SwapExecuted")
        .withArgs(
          user.address,
          await weth.getAddress(),
          wethAmount,
          hardhat.ethers.parseEther("1"),
          hardhat.ethers.parseEther("0.97"),
          hardhat.ethers.parseEther("0.015"),
          hardhat.ethers.parseEther("0.015"),
          customData,
          maintainer.address
        );
    });

    it("should handle large bytes data", async function () {
      const wethAmount = hardhat.ethers.parseEther("1");
      const deadline = Math.floor(Date.now() / 1000) + 3600;

      // Fund user with WETH
      await weth.connect(user).deposit({ value: wethAmount });

      // Create permit signature
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

      // Test with large bytes data (1KB of data)
      const largeData = new Uint8Array(1024).fill(42); // 1KB of data filled with value 42

      const tx = await executor.connect(maintainer).executeSwap(
        await weth.getAddress(),
        3000,
        wethAmount,
        hardhat.ethers.parseEther("0.9"),
        0,
        user.address,
        largeData,
        deadline,
        v,
        r,
        s
      );

      const receipt = await tx.wait();
      const event = receipt.logs.find((log: any) => log.fragment?.name === "SwapExecuted");
      expect(event).to.not.be.undefined;
      expect(event.args.data).to.equal("0x" + Array.from(largeData).map(b => b.toString(16).padStart(2, '0')).join(''));
    });
  });
});