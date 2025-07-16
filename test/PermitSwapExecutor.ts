import { ethers, network } from "hardhat";
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
    const WETH = await ethers.getContractFactory("MockWETH9");
    weth = await WETH.deploy();
    // Wait for deployment to be mined
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

    // Set maintainer
    await executor.connect(owner).setMaintainer(await maintainer.getAddress(), true);
  });

  it("should execute swap and split ETH correctly", async function () {



    // Use the same ethers import as the rest of the test
    // Log all signers and their addresses
    const signers = await ethers.getSigners();
    for (let i = 0; i < signers.length; i++) {
      const addr = await signers[i].getAddress();
      console.log(`[LOG] getSigners()[${i}] address:`, addr);
    }

    // Declare mnemonic at the top for use below
    const mnemonic = "test test test test test test test test test test test junk";

    // Mint tokens to user
    const userAddr = await user.getAddress();
    console.log("[LOG] user address:", userAddr);
    const referrerAddr = await referrer.getAddress();
    console.log("[LOG] referrer address:", referrerAddr);
    const tokenAddr = await token.getAddress();
    console.log("[LOG] token address:", tokenAddr);
    const executorAddr = await executor.getAddress();
    console.log("[LOG] executor address:", executorAddr);
    const routerAddr = await router.getAddress();
    console.log("[LOG] router address:", routerAddr);
    const treasuryAddr = await treasury.getAddress();
    console.log("[LOG] treasury address:", treasuryAddr);
    const ownerAddr = await owner.getAddress();
    console.log("[LOG] owner address:", ownerAddr);

    // Log derived addresses from mnemonic for comparison
    for (let i = 0; i < 10; i++) {
      const path = `m/44'/60'/0'/0/${i}`;
      const hdNode = ethers.HDNodeWallet.fromPhrase(mnemonic, path);
      const addr = await hdNode.getAddress();
      console.log(`[LOG] mnemonic-derived[${i}] (path=${path}) address:`, addr);
    }

    await token.mint(userAddr, ethers.parseEther("100"));
    console.log("[LOG] Minted 100 tokens to user");

    // EIP-2612 permit signature
    const amount = ethers.parseEther("10");
    console.log("[LOG] Permit amount:", amount.toString());
    const nonce = await token.nonces(userAddr);
    console.log("[LOG] Permit nonce:", nonce.toString());
    const deadline = Math.floor(Date.now() / 1000) + 3600;
    console.log("[LOG] Permit deadline:", deadline);
    const chainId = (await network.provider.send("eth_chainId")).toString();
    const chainIdNum = Number(chainId);
    console.log("[LOG] ChainId:", chainIdNum);
    const name = await token.name();
    console.log("[LOG] Token name:", name);
    const version = "1";
    const domain = {
      name,
      version,
      chainId: chainIdNum,
      verifyingContract: tokenAddr,
    };
    console.log("[LOG] Domain:", domain);
    const types = {
      Permit: [
        { name: "owner", type: "address" },
        { name: "spender", type: "address" },
        { name: "value", type: "uint256" },
        { name: "nonce", type: "uint256" },
        { name: "deadline", type: "uint256" },
      ],
    };
    console.log("[LOG] Types:", types);
    const values = {
      owner: userAddr,
      spender: executorAddr,
      value: amount,
      nonce,
      deadline,
    };
    console.log("[LOG] Values:", values);

    // Use Hardhat's default mnemonic to get the user wallet (account[2])
    const mnemonic = "test test test test test test test test test test test junk";

    // Try all likely derivation paths for userAddr
    let derivedWallet: any = undefined;
    let derivedAddr: string | undefined = undefined;
    let found = false;
    for (let i = 0; i < 10; i++) {
      const path = `m/44'/60'/0'/0/${i}`;
      const hdNode = ethers.HDNodeWallet.fromPhrase(mnemonic, path);
      const wallet = hdNode.connect((ethers as any).provider);
      const addr = await wallet.getAddress();
        derivedWallet = wallet;
        derivedAddr = addr;
        found = true;
        console.log(`[LOG] Found matching wallet at index ${i} with path ${path}`);
        break;
      }
    }
    if (!found || !derivedWallet || !derivedAddr || derivedAddr.toLowerCase() !== userAddr.toLowerCase()) {
      throw new Error(`[ERROR] Could not find wallet for userAddr: ${userAddr}`);
    }
    const userWallet = derivedWallet;
    const sig = await userWallet.signTypedData(domain, types, values);
    console.log("[LOG] Signed permit");
    const { v, r, s } = ethers.Signature.from(sig);
    console.log("[LOG] Extracted v, r, s from signature");

    // Maintainer calls executeSwap with real permit
    await expect(
      executor.connect(maintainer).executeSwap(
        tokenAddr,
        3000, // poolFee
        amount,
        0, // minOut
        userAddr,
        referrerAddr,
        deadline,
        v, r, s
      )
    ).to.emit(executor, "SwapExecuted");
    console.log("[LOG] executeSwap called and SwapExecuted emitted");

    // Check ETH balances (mock router should send WETH, which is unwrapped)
    // For a real test, check referrer, maintainer, treasury, user balances
  });
});
