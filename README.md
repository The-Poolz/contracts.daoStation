# PermitSwapExecutor

A secure and modular smart contract that enables gasless token swaps using `ERC-2612 permit`, Uniswap integration, and reward distribution — all in a single atomic transaction.

## 🧩 Key Features

- 📝 Accepts off-chain signed `permit()` from users (ERC-2612)
- 🔁 Swaps any ERC-20 token to WETH via Uniswap
- 💧 Unwraps WETH to ETH
- 📤 Sends ETH to:
  - 1.5% Maintainer (`msg.sender`)
  - 1.5% Contract Treasury
  - 97% Back to original user
- 🔐 Only approved maintainers can execute logic
- 🛡️ Protected against reentrancy attacks

---

## 🚀 Use Case

Allows a user to authorize a token swap and payout **without sending any transaction** themselves.  
Instead, a trusted maintainer executes the flow on their behalf using a signature.

---

## 🔒 Trust Model

| Role         | Source           | Description                       |
|--------------|------------------|-----------------------------------|
| User (Owner) | Permit Signature | Owns the tokens                   |
| Maintainer   | msg.sender       | Must be whitelisted, gets 1.5%   |
| Contract     | address(this)    | Keeps 1.5% for gas/treasury      |

---

## 📦 Contract Flow

1. ✅ `permit()` is called using the user’s signature
2. ✅ Tokens are `transferFrom()` user's wallet to contract
3. 🔁 Tokens are swapped to **WETH** via Uniswap
4. 🔁 WETH is unwrapped to **ETH**
5. 💸 ETH is split:
   - `1.5%` → `msg.sender` (maintainer)
   - `1.5%` → Contract (treasury)
   - `97%` → User (original signer)
6. 🔐 All actions are performed atomically

---

## ⚙️ Functions

### `executeSwap(...)`

Executes the full logic in one transaction:

- `permit` usage
- Swap via Uniswap
- ETH distribution

> Can only be called by an **authorized maintainer**

---

## 🛡 Security Notes

- Uses ERC-2612 `nonces` to prevent replay attacks
- Requires tight `deadline` on `permit()`
- `msg.sender` is validated against an allowlist of maintainers
- Contract includes `receive()` and `fallback()` to handle ETH
- **Protected against reentrancy attacks** using OpenZeppelin's ReentrancyGuard
- All critical functions use `nonReentrant` modifier

---

## 📜 Requirements

- Token must support `ERC-2612` (e.g. USDC, DAI, etc)
- Swap pair must exist on Uniswap V3
- Contract must be pre-approved in `permit()` signature
- Maintainer must be whitelisted by contract owner

---

## 🏗️ Architecture

The contract is built with a modular architecture:

- **`PermitSwapExecutor`** - Main contract that orchestrates the entire flow
- **`TreasuryManager`** - Handles fee distribution and treasury management
- **`SwapHelper`** - Manages token preparation, Uniswap swaps, and WETH operations

---

## 🧪 Testing

Run the comprehensive test suite:

```bash
# Install dependencies
pnpm install

# Run all tests
pnpm test

# Run with coverage
npx hardhat coverage
```

Current test coverage: **95.45%** statements, **86.67%** functions

---

## 🚀 Deployment

1. Deploy the contract with:

   ```solidity
   constructor(address _uniswapRouter, address initialOwner)
   ```

2. Set authorized maintainers:

   ```solidity
   setMaintainer(address maintainer, bool allowed)
   ```

3. Users can then execute gasless swaps via maintainers

---

## 🧠 Example

User signs:

```solidity
## 🧠 Example

User creates a permit signature off-chain:

```solidity
permit(owner, spender=PermitSwapExecutor, value, deadline, v, r, s)
```

Maintainer executes the swap:

```solidity
executeSwap(
    tokenIn,       // ERC20 token address
    poolFee,       // Uniswap pool fee (3000 = 0.3%)
    amountIn,      // Amount of tokens to swap
    amountOutMin,  // Minimum ETH to receive
    sqrtPriceLimitX96, // Price limit (0 = no limit)
    user,          // Original token owner
    data,          // Arbitrary bytes data to include with swap
    deadline,      // Permit deadline
    v, r, s        // Permit signature components
)
```

Result: User receives 97% of swapped ETH, maintainer gets 1.5%, treasury keeps 1.5%

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.
