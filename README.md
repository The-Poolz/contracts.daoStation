# PermitSwapExecutor

A secure and modular smart contract that enables gasless token swaps using `ERC-2612 permit`, Uniswap integration, and reward distribution — all in a single atomic transaction.

## 🧩 Key Features

- 📝 Accepts off-chain signed `permit()` from users (ERC-2612)
- 🔁 Swaps any ERC-20 token to WETH via Uniswap
- 💧 Unwraps WETH to ETH
- 📤 Sends ETH to:
  - 1% Referrer (optional)
  - 1% Maintainer (`msg.sender`)
  - 1% Contract Treasury
  - 97% Back to original user
- 🔐 Only approved maintainers can execute logic

---

## 🚀 Use Case

Allows a user to authorize a token swap and payout **without sending any transaction** themselves.  
Instead, a trusted maintainer executes the flow on their behalf using a signature.

---

## 🔒 Trust Model

| Role         | Source           | Description                    |
|--------------|------------------|--------------------------------|
| User (Owner) | Permit Signature | Owns the tokens                |
| Referrer     | Calldata Param   | Optional, gets 1% of ETH       |
| Maintainer   | msg.sender       | Must be whitelisted, gets 1%   |
| Contract     | address(this)    | Keeps 1% for gas/treasury      |

---

## 📦 Contract Flow

1. ✅ `permit()` is called using the user’s signature
2. ✅ Tokens are `transferFrom()` user's wallet to contract
3. 🔁 Tokens are swapped to **WETH** via Uniswap
4. 🔁 WETH is unwrapped to **ETH**
5. 💸 ETH is split:
   - `1%` → Referrer
   - `1%` → `msg.sender` (maintainer)
   - `1%` → Contract (treasury)
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

- Uses ERC-2612 `nonces` to prevent replay
- Requires tight `deadline` on `permit()`
- `msg.sender` is validated against an allowlist of maintainers
- Contract includes `receive()` or `fallback()` to handle ETH

---

## 📜 Requirements

- Token must support `ERC-2612` (e.g. USDC, DAI, etc)
- Swap pair must exist on Uniswap
- Contract must be pre-approved in `permit()` signature
- Referrer can be `address(0)` if unused

---

## 🧠 Example

User signs:

```solidity
permit(owner, spender=PermitSwapExecutor, value, deadline, v, r, s)
