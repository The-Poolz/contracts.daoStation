# PermitSwapExecutor

[![Build and Test](https://github.com/The-Poolz/contracts.daoStation/actions/workflows/build.yml/badge.svg)](https://github.com/The-Poolz/contracts.daoStation/actions/workflows/build.yml)
[![codecov](https://codecov.io/gh/The-Poolz/contracts.daoStation/graph/badge.svg)](https://codecov.io/gh/The-Poolz/contracts.daoStation)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/The-Poolz/contracts.daoStation/blob/master/LICENSE)

A secure and modular smart contract that enables gasless token swaps using `ERC-2612 permit`, Uniswap integration, and reward distribution — all in a single atomic transaction.

## 🧩 Key Features

- 📝 Accepts off-chain signed `permit()` from users (ERC-2612)
- 🔁 Swaps any ERC-20 token to WETH via Uniswap Universal Router
- 💧 Unwraps WETH to ETH
- 📤 Sends ETH to:
  - Fixed fee to Maintainer (`msg.sender`) - default 0.01 ETH
  - Fixed fee to Contract Treasury - default 0.01 ETH  
  - Remainder back to original user
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
| Maintainer   | msg.sender       | Must be whitelisted, gets fixed fee (default 0.01 ETH)   |
| Contract     | address(this)    | Keeps fixed fee for gas/treasury (default 0.01 ETH)      |

---

## 📦 Contract Flow

1. ✅ `permit()` is called using the user’s signature
2. ✅ Tokens are `transferFrom()` user's wallet to contract
3. 🔁 Tokens are swapped to **WETH** via Uniswap Universal Router
4. 🔁 WETH is unwrapped to **ETH**
5. 💸 ETH is split:
   - Fixed fee → `msg.sender` (maintainer) - default 0.01 ETH
   - Fixed fee → Contract (treasury) - default 0.01 ETH
   - Remainder → User (original signer)
6. 🔐 All actions are performed atomically

---

## ⚙️ Functions

### `executeSwap(...)`

Executes the full logic in one transaction using Uniswap's Universal Router:

- `permit` usage
- Swap via Uniswap Universal Router
- ETH distribution

> Can only be called by an **authorized maintainer**

**Function signature:**
```solidity
function executeSwap(
    address tokenIn,        // The ERC-20 token to swap (must support ERC-2612 permit)
    bytes calldata commands,// The encoded commands for UniversalRouter execution
    bytes[] calldata inputs,// The encoded inputs array corresponding to the commands
    address user,           // The original token owner who signed the permit
    bytes calldata data,    // Arbitrary bytes data to include with the swap
    uint deadline,          // The permit signature deadline
    uint8 v, bytes32 r, bytes32 s  // Permit signature components
) external
```

### `isValidSignature(...)`

Pure function for validating ERC-2612 permit signatures:

- **Purpose**: Validates permit signatures without making external calls
- **Parameters**: User address, spender, amount, deadline, nonce, domain separator, and signature components (v, r, s)
- **Returns**: Boolean indicating signature validity
- **Usage**: Can be used for off-chain validation or within view functions
- **Gas Efficient**: Pure function with no state changes or external calls

```solidity
function isValidSignature(
    address user,           // The expected signer
    address spender,        // The authorized spender
    uint256 amountIn,       // The permitted amount
    uint256 deadline,       // The signature deadline
    uint256 nonce,          // User's current nonce
    bytes32 domainSeparator,// Token's domain separator
    uint8 v, bytes32 r, bytes32 s  // Signature components
) public pure returns (bool isValid)
```

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
- Swap routes must be supported by Uniswap Universal Router
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
pnpm hardhat coverage
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

User creates a permit signature off-chain:

```solidity
permit(owner, spender=PermitSwapExecutor, value, deadline, v, r, s)
```

Maintainer executes the swap:

```solidity
executeSwap(
    tokenIn,       // ERC-20 token address (must support ERC-2612 permit)
    commands,      // The encoded commands for UniversalRouter execution
    inputs,        // The encoded inputs array corresponding to the commands
    user,          // The original token owner who signed the permit
    data,          // Arbitrary bytes data to include with the swap
    deadline,      // The permit signature deadline
    v, r, s        // Permit signature components
)
```

Result: User receives swapped ETH minus fixed fees, maintainer gets fixed fee (default 0.01 ETH), treasury keeps fixed fee (default 0.01 ETH)

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.
