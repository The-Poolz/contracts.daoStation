import { ethers } from "hardhat";
import { expect } from "chai";
import { Contract, Signer } from "ethers";

describe("PermitSwapExecutor", function () {
  let owner: Signer, maintainer: Signer, user: Signer, referrer: Signer, treasury: Signer;
  let executor: Contract;
  let token: Contract;
  let weth: Contract;
  let router: Contract;

  beforeEach(async function () {
    [owner, maintainer, user, referrer, treasury] = await ethers.getSigners();

    // Deploy mock WETH
    const WETH = await ethers.getContractFactory("WETH9");
    weth = await WETH.deploy();
    await weth.deployed();

    // Deploy mock ERC20 with permit
    const MockERC20Permit = await ethers.getContractFactory("MockERC20Permit");
    token = await MockERC20Permit.deploy("MockToken", "MTK", 18);
    await token.deployed();

    // Deploy mock Uniswap V3 router
    const MockSwapRouter = await ethers.getContractFactory("MockSwapRouterV3");
    router = await MockSwapRouter.deploy(weth.address);
    await router.deployed();

    // Deploy PermitSwapExecutor
    const PermitSwapExecutor = await ethers.getContractFactory("PermitSwapExecutor");
    executor = await PermitSwapExecutor.deploy(router.address, await treasury.getAddress());
    await executor.deployed();

    // Set maintainer
    await executor.connect(owner).setMaintainer(await maintainer.getAddress(), true);
  });

  it("should execute swap and split ETH correctly", async function () {
    // Mint tokens to user
    await token.mint(await user.getAddress(), ethers.utils.parseEther("100"));

    // User approves executor via permit (mocked)
    // For real test, use EIP-2612 signature logic
    await token.connect(user).approve(executor.address, ethers.utils.parseEther("10"));

    // Maintainer calls executeSwap
    await expect(
      executor.connect(maintainer).executeSwap(
        token.address,
        3000, // poolFee
        ethers.utils.parseEther("10"),
        0, // minOut
        await user.getAddress(),
        await referrer.getAddress(),
        Math.floor(Date.now() / 1000) + 3600,
        0, "0x", "0x" // dummy permit
      )
    ).to.emit(executor, "SwapExecuted");

    // Check ETH balances (mock router should send WETH, which is unwrapped)
    // For a real test, check referrer, maintainer, treasury, user balances
  });
});
