const hardhat = require("hardhat");
const chaiModule = require("chai");
const expect = chaiModule.expect;

describe("MockERC20Permit", function () {
  let owner: any, spender: any, receiver: any;
  let token: any;

  beforeEach(async function () {
    const signers = await hardhat.ethers.getSigners();
    [owner, spender, receiver] = signers;

    // Deploy mock ERC20 with permit
    const MockERC20Permit = await hardhat.ethers.getContractFactory("MockERC20Permit");
    token = await MockERC20Permit.deploy("MockToken", "MTK", 18);
    await token.waitForDeployment();
  });

  it("should deploy with correct name and symbol", async function () {
    const name = await token.name();
    const symbol = await token.symbol();
    const decimals = await token.decimals();
    
    expect(name).to.equal("MockToken");
    expect(symbol).to.equal("MTK");
    expect(decimals).to.equal(18);
  });

  it("should mint tokens to owner", async function () {
    const amount = hardhat.ethers.parseEther("1000");
    await token.mint(owner.address, amount);
    
    const balance = await token.balanceOf(owner.address);
    expect(balance).to.equal(amount);
  });

  it("should have permit domain separator", async function () {
    const domainSeparator = await token.DOMAIN_SEPARATOR();
    expect(domainSeparator).to.not.equal("0x0000000000000000000000000000000000000000000000000000000000000000");
  });

  it("should permit transfer from A to B", async function () {
    const amount = hardhat.ethers.parseEther("100");
    
    // Mint tokens to owner
    await token.mint(owner.address, amount);
    
    // Get initial balances
    const ownerInitialBalance = await token.balanceOf(owner.address);
    const receiverInitialBalance = await token.balanceOf(receiver.address);
    
    // Create permit signature
    const deadline = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
    const nonce = await token.nonces(owner.address);
    
    const domain = {
      name: await token.name(),
      version: "1",
      chainId: 31337, // Hardhat default chain ID
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
      owner: owner.address,
      spender: spender.address,
      value: amount,
      nonce: nonce,
      deadline: deadline
    };
    
    const signature = await owner.signTypedData(domain, types, value);
    const { v, r, s } = hardhat.ethers.Signature.from(signature);
    
    // Use permit and transfer in one transaction
    await token.permit(owner.address, spender.address, amount, deadline, v, r, s);
    await token.connect(spender).transferFrom(owner.address, receiver.address, amount);
    
    // Check final balances
    const ownerFinalBalance = await token.balanceOf(owner.address);
    const receiverFinalBalance = await token.balanceOf(receiver.address);
    
    expect(ownerFinalBalance).to.equal(ownerInitialBalance - amount);
    expect(receiverFinalBalance).to.equal(receiverInitialBalance + amount);
  });
});
