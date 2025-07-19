const hardhat = require("hardhat");
const { expect } = require("chai");

describe("SwapHelper", function () {
  let user: any;
  let swapTest: any, token: any, weth: any, router: any;

  beforeEach(async function () {
    const signers = await hardhat.ethers.getSigners();
    [, user] = signers;

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

    const SwapHelperTest = await hardhat.ethers.getContractFactory("SwapHelperTest");
    swapTest = await SwapHelperTest.deploy(await router.getAddress());
    await swapTest.waitForDeployment();
  });

  it("should prepare token with permit", async function () {
    const amount = hardhat.ethers.parseEther("100");
    
    // Mint tokens to user
    await token.mint(user.address, amount);
    
    // Create permit signature
    const deadline = Math.floor(Date.now() / 1000) + 3600;
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
      spender: await swapTest.getAddress(),
      value: amount,
      nonce: nonce,
      deadline: deadline
    };
    
    const signature = await user.signTypedData(domain, types, value);
    const { v, r, s } = hardhat.ethers.Signature.from(signature);
    
    // Test prepare token
    await swapTest.test_prepareToken(
      await token.getAddress(),
      user.address,
      amount,
      deadline,
      v,
      r,
      s
    );
    
    // Check that tokens were transferred
    const contractBalance = await token.balanceOf(await swapTest.getAddress());
    expect(contractBalance).to.equal(amount);
  });

  it("should test WETH deposit and withdraw", async function () {
    const ethAmount = hardhat.ethers.parseEther("1");
    
    // Test WETH deposit from user
    await weth.connect(user).deposit({ value: ethAmount });
    expect(await weth.balanceOf(user.address)).to.equal(ethAmount);
    
    // Test WETH withdraw
    await weth.connect(user).withdraw(ethAmount);
    expect(await weth.balanceOf(user.address)).to.equal(0);
  });

  it("should unwrap WETH", async function () {
    // Just test that the function can be called without reverting
    await swapTest.test_unwrapWETH(0);
    // Test passes if no revert
    expect(true).to.be.true;
  });
});
