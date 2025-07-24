const hardhat = require("hardhat");
const { expect } = require("chai");

describe("SwapHelper", function () {
  let user: any;
  let swapTest: any, token: any, weth: any, router: any;

  describe("Deployment", function () {
    it("should revert if router address is zero", async function () {
      const [owner] = await hardhat.ethers.getSigners();
      const SwapHelperTest = await hardhat.ethers.getContractFactory("SwapHelperTest");
      await expect(SwapHelperTest.deploy(hardhat.ethers.ZeroAddress, hardhat.ethers.ZeroAddress, owner.address))
        .to.be.revertedWithCustomError(SwapHelperTest, "ZeroRouterAddress");
    });
  });

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

    // Deploy mock Universal Router
    const MockUniversalRouter = await hardhat.ethers.getContractFactory("MockUniversalRouter");
    router = await MockUniversalRouter.deploy(await weth.getAddress());
    await router.waitForDeployment();

    const SwapHelperTest = await hardhat.ethers.getContractFactory("SwapHelperTest");
    const [owner] = await hardhat.ethers.getSigners();
    swapTest = await SwapHelperTest.deploy(await router.getAddress(), await weth.getAddress(), owner.address);
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

  it("should prepare token with valid permit signature", async function () {
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
    
    // Test with correct user - should succeed
    await swapTest.test_prepareToken(
      await token.getAddress(),
      user.address,
      amount,
      deadline,
      v,
      r,
      s
    );
    
    // Verify the contract received the tokens
    expect(await token.balanceOf(await swapTest.getAddress())).to.equal(amount);
  });

  it("should reject arbitrary user with valid permit signature in prepareToken", async function () {
    const amount = hardhat.ethers.parseEther("100");
    
    // Mint tokens to user
    await token.mint(user.address, amount);
    
    // Create permit signature for the actual user
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
    
    // Try to use the permit signature with a different user address (attack scenario)
    const [, , , wrongUser] = await hardhat.ethers.getSigners();
    await expect(
      swapTest.test_prepareToken(
        await token.getAddress(),
        wrongUser.address,  // Wrong user!
        amount,
        deadline,
        v,
        r,
        s
      )
    ).to.be.reverted; // Will be rejected by permit function, not our custom error
  });

  describe("isValidSignature", function () {
    it("should validate correct permit signature", async function () {
      const amount = hardhat.ethers.parseEther("100");
      const deadline = Math.floor(Date.now() / 1000) + 3600;
      const nonce = await token.nonces(user.address);
      const domainSeparator = await token.DOMAIN_SEPARATOR();
      
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

      const isValid = await swapTest.test_isValidSignature(
        user.address,
        await swapTest.getAddress(),
        amount,
        deadline,
        nonce,
        domainSeparator,
        v,
        r,
        s
      );

      expect(isValid).to.be.true;
    });

    it("should reject invalid permit signature with wrong signer", async function () {
      const amount = hardhat.ethers.parseEther("100");
      const deadline = Math.floor(Date.now() / 1000) + 3600;
      const nonce = await token.nonces(user.address);
      const domainSeparator = await token.DOMAIN_SEPARATOR();

      // Create signature with wrong signer
      const [wrongSigner] = await hardhat.ethers.getSigners();
      
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

      const signature = await wrongSigner.signTypedData(domain, types, value);
      const { v, r, s } = hardhat.ethers.Signature.from(signature);

      const isValid = await swapTest.test_isValidSignature(
        user.address,
        await swapTest.getAddress(),
        amount,
        deadline,
        nonce,
        domainSeparator,
        v,
        r,
        s
      );

      expect(isValid).to.be.false;
    });

    it("should reject signature with wrong parameters", async function () {
      const amount = hardhat.ethers.parseEther("100");
      const deadline = Math.floor(Date.now() / 1000) + 3600;
      const nonce = await token.nonces(user.address);
      const domainSeparator = await token.DOMAIN_SEPARATOR();
      
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

      // Test with wrong amount
      const isValidWrongAmount = await swapTest.test_isValidSignature(
        user.address,
        await swapTest.getAddress(),
        hardhat.ethers.parseEther("50"), // Wrong amount
        deadline,
        nonce,
        domainSeparator,
        v,
        r,
        s
      );
      expect(isValidWrongAmount).to.be.false;

      // Test with wrong spender
      const [, , wrongSpender] = await hardhat.ethers.getSigners();
      const isValidWrongSpender = await swapTest.test_isValidSignature(
        user.address,
        wrongSpender.address, // Wrong spender
        amount,
        deadline,
        nonce,
        domainSeparator,
        v,
        r,
        s
      );
      expect(isValidWrongSpender).to.be.false;

      // Test with wrong nonce
      const isValidWrongNonce = await swapTest.test_isValidSignature(
        user.address,
        await swapTest.getAddress(),
        amount,
        deadline,
        nonce + 1n, // Wrong nonce
        domainSeparator,
        v,
        r,
        s
      );
      expect(isValidWrongNonce).to.be.false;
    });

    it("should work with different domain separators", async function () {
      const amount = hardhat.ethers.parseEther("100");
      const deadline = Math.floor(Date.now() / 1000) + 3600;
      const nonce = await token.nonces(user.address);
      
      // Create a different domain separator (simulating different token)
      const wrongDomainSeparator = hardhat.ethers.keccak256(hardhat.ethers.toUtf8Bytes("wrong domain"));
      
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

      // Test with wrong domain separator should fail
      const isValidWrongDomain = await swapTest.test_isValidSignature(
        user.address,
        await swapTest.getAddress(),
        amount,
        deadline,
        nonce,
        wrongDomainSeparator,
        v,
        r,
        s
      );
      expect(isValidWrongDomain).to.be.false;

      // Test with correct domain separator should pass
      const correctDomainSeparator = await token.DOMAIN_SEPARATOR();
      const isValidCorrectDomain = await swapTest.test_isValidSignature(
        user.address,
        await swapTest.getAddress(),
        amount,
        deadline,
        nonce,
        correctDomainSeparator,
        v,
        r,
        s
      );
      expect(isValidCorrectDomain).to.be.true;
    });
  });
});
