const { ethers, network } = require("hardhat");
const { expect } = require("chai");

describe("PermitSwapExecutor", function () {
  let owner, maintainer, user, referrer, treasury;
  let executor, token, weth, router;

  beforeEach(async function () {
    const signers = await ethers.getSigners();
    [owner, maintainer, user, referrer, treasury] = signers;

    // Deploy mock WETH
    const WETH = await ethers.getContractFactory("MockWETH9");
    weth = await WETH.deploy();
    await weth.waitForDeployment();

    // Deploy mock ERC20 with permit
    const MockERC20Permit = await ethers.getContractFactory("MockERC20Permit");
    token = await MockERC20Permit.deploy("MockToken", "MTK", 18);
    await token.waitForDeployment();

    // Deploy mock Uniswap V3 router
    const MockSwapRouter = await ethers.getContractFactory("MockSwapRouterV3");
    router = await MockSwapRouter.deploy(await weth.getAddress());
    await router.waitForDeployment();

    // Deploy PermitSwapExecutor
    const PermitSwapExecutor = await ethers.getContractFactory("PermitSwapExecutor");
    executor = await PermitSwapExecutor.deploy(
      await router.getAddress(),
      await treasury.getAddress(),
      await owner.getAddress()
    );
    await executor.waitForDeployment();
  });

  it("should deploy and check immutable addresses", async function () {
    // Check router address
    const routerAddr = await executor.uniswapRouter();
    const expectedRouter = await router.getAddress();
    expect(routerAddr).to.equal(expectedRouter);

    // Check treasury address  
    const treasuryAddr = await executor.treasury();
    const expectedTreasury = await treasury.getAddress();
    expect(treasuryAddr).to.equal(expectedTreasury);

    // Check WETH address
    const wethAddr = await executor.WETH();
    const expectedWeth = await weth.getAddress();
    expect(wethAddr).to.equal(expectedWeth);
  });

  it("should add maintainer", async function () {
    // Check maintainer is not set initially
    const maintainerAddr = await maintainer.getAddress();
    let isMaintainer = await executor.isMaintainer(maintainerAddr);
    expect(isMaintainer).to.be.false;

    // Set maintainer
    await executor.connect(owner).setMaintainer(maintainerAddr, true);

    // Check maintainer is now set
    isMaintainer = await executor.isMaintainer(maintainerAddr);
    expect(isMaintainer).to.be.true;

    // Remove maintainer
    await executor.connect(owner).setMaintainer(maintainerAddr, false);

    // Check maintainer is now removed
    isMaintainer = await executor.isMaintainer(maintainerAddr);
    expect(isMaintainer).to.be.false;
  });
});
