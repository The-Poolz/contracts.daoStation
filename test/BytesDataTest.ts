const hardhat = require("hardhat");
const { expect } = require("chai");

// Helper function to build swap commands and inputs
function buildSwapParams(tokenIn: string, poolFee: number, amountIn: bigint, amountOutMin: bigint, recipient: string, wethAddress: string) {
  // Create command (V3_SWAP_EXACT_IN = 0x00)
  const commands = hardhat.ethers.solidityPacked(["uint8"], [0x00]);
  
  // Encode the path for Uniswap V3: tokenIn -> poolFee -> WETH
  const path = hardhat.ethers.solidityPacked(
    ["address", "uint24", "address"], 
    [tokenIn, poolFee, wethAddress]
  );
  
  // Encode inputs for V3_SWAP_EXACT_IN command
  // Parameters: (address recipient, uint256 amountIn, uint256 amountOutMin, bytes path, bool payerIsUser)
  const inputs = [
    hardhat.ethers.AbiCoder.defaultAbiCoder().encode(
      ["address", "uint256", "uint256", "bytes", "bool"],
      [recipient, amountIn, amountOutMin, path, false]
    )
  ];
  
  return { commands, inputs };
}

// Helper function to build swap+unwrap commands and inputs
function buildSwapAndUnwrapParams(tokenIn: string, poolFee: number, amountIn: bigint, amountOutMin: bigint, recipient: string, wethAddress: string) {
  // Commands: 0x00 = V3_SWAP_EXACT_IN, 0x0c = UNWRAP_WETH  
  const commands = hardhat.ethers.solidityPacked(["uint8", "uint8"], [0x00, 0x0c]);
  
  const path = hardhat.ethers.solidityPacked(
    ["address", "uint24", "address"], 
    [tokenIn, poolFee, wethAddress]
  );
  
  // Input 1: V3_SWAP_EXACT_IN parameters
  const swapInput = hardhat.ethers.AbiCoder.defaultAbiCoder().encode(
    ["address", "uint256", "uint256", "bytes", "bool"],
    [wethAddress, amountIn, amountOutMin, path, false] // recipient is WETH for intermediate step
  );
  
  // Input 2: UNWRAP_WETH parameters 
  const unwrapInput = hardhat.ethers.AbiCoder.defaultAbiCoder().encode(
    ["address", "uint256"],
    [recipient, amountIn] // recipient gets ETH, amount is expected 1:1 output
  );
  
  return { commands, inputs: [swapInput, unwrapInput] };
}

// Helper function to build WETH-only unwrap commands and inputs
function buildWETHUnwrapParams(amountIn: bigint, recipient: string) {
  // Commands: 0x0c = UNWRAP_WETH only
  const commands = hardhat.ethers.solidityPacked(["uint8"], [0x0c]);
  
  // Single input: UNWRAP_WETH parameters
  const inputs = [
    hardhat.ethers.AbiCoder.defaultAbiCoder().encode(
      ["address", "uint256"],
      [recipient, amountIn]
    )
  ];
  
  return { commands, inputs };
}

describe("PermitSwapExecutor Bytes Data", function () {
  let owner: any, maintainer: any, user: any;
  let executor: any, token: any, weth: any, router: any, permit2: any;

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

    // Deploy mock Permit2
    const MockPermit2 = await hardhat.ethers.getContractFactory("MockPermit2");
    permit2 = await MockPermit2.deploy();
    await permit2.waitForDeployment();

    // Deploy mock Universal router
    const MockUniversalRouter = await hardhat.ethers.getContractFactory("MockUniversalRouter");
    router = await MockUniversalRouter.deploy(await weth.getAddress(), await permit2.getAddress());
    await router.waitForDeployment();

    // Deploy main PermitSwapExecutor
    const PermitSwapExecutor = await hardhat.ethers.getContractFactory("PermitSwapExecutor");
    executor = await PermitSwapExecutor.deploy(
      await router.getAddress(),
      await weth.getAddress(),
      await permit2.getAddress()
    );
    await executor.waitForDeployment();

    // Set maintainer
    await executor.connect(owner).setMaintainer(maintainer.address, true);
    
    // Fund router with ETH for unwrapping operations
    await owner.sendTransaction({
      to: await router.getAddress(),
      value: hardhat.ethers.parseEther("10")
    });
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
      
      // Fund router with ETH for unwrapping operations
      const ethAmount = hardhat.ethers.parseEther("2");
      await owner.sendTransaction({
        to: await router.getAddress(),
        value: ethAmount
      });

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
      
      // Build swap and unwrap parameters
      const { commands, inputs } = buildSwapAndUnwrapParams(
        await token.getAddress(),
        3000,
        tokenAmount,
        hardhat.ethers.parseEther("0.9"),
        await executor.getAddress(),
        await weth.getAddress()
      );

      await expect(executor.connect(maintainer).executeSwap(
        await token.getAddress(),
        commands,
        inputs,
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
          hardhat.ethers.parseEther("1.0"), // 1.0 ETH received (1:1 swap)
          hardhat.ethers.parseEther("0.98"), // 0.98 eth to user (1.0 - 0.02 fees)
          hardhat.ethers.parseEther("0.01"), // 0.01 eth to maintainer (actual value)
          hardhat.ethers.parseEther("0.01"), // 0.01 eth to treasury (actual value)
          emptyData,
          maintainer.address
        );
    });

    it("should emit SwapExecuted with custom bytes data", async function () {
      const wethAmount = hardhat.ethers.parseEther("1");
      const deadline = Math.floor(Date.now() / 1000) + 3600;

      // Fund router with ETH for unwrapping operations
      const ethAmount = hardhat.ethers.parseEther("2");
      await owner.sendTransaction({
        to: await router.getAddress(),
        value: ethAmount
      });

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
      
      // Build WETH unwrap parameters
      const { commands, inputs } = buildWETHUnwrapParams(
        wethAmount,
        await executor.getAddress()
      );

      await expect(executor.connect(maintainer).executeSwap(
        await weth.getAddress(),
        commands,
        inputs,
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
          hardhat.ethers.parseEther("0.98"),
          hardhat.ethers.parseEther("0.01"),
          hardhat.ethers.parseEther("0.01"),
          customData,
          maintainer.address
        );
    });

    it("should handle large bytes data", async function () {
      const wethAmount = hardhat.ethers.parseEther("1");
      const deadline = Math.floor(Date.now() / 1000) + 3600;

      // Fund router with ETH for unwrapping operations
      const ethAmount = hardhat.ethers.parseEther("2");
      await owner.sendTransaction({
        to: await router.getAddress(),
        value: ethAmount
      });

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
      
      // Build WETH unwrap parameters
      const { commands, inputs } = buildWETHUnwrapParams(
        wethAmount,
        await executor.getAddress()
      );

      const tx = await executor.connect(maintainer).executeSwap(
        await weth.getAddress(),
        commands,
        inputs,
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