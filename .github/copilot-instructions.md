# Copilot Custom Instructions

Package management is done using `pnpm`. When writing setup instructions or scripts, always use `pnpm` commands instead of `npm` or `yarn`. Examples:

-   Install dependencies: `pnpm install`
-   Run tests: `pnpm test`
-   Run coverage: `pnpm hardhat coverage`

Our project uses Solidity version 0.8.28 with `viaIR` enabled and optimizer set to 200 runs. Always use the latest best practices for Solidity 0.8.x when generating code or providing advice.

The project uses Hardhat with TypeScript for development and testing. Any examples involving testing should use Hardhat and ethers.js (version 6) with TypeScript syntax.

The code style follows the OpenZeppelin standard: clear function visibility (`public`, `external`, `internal`, `private`), NatSpec documentation comments for all public and external functions, and minimal inline comments for internal logic.

The project relies on Uniswap V3 integration. Always suggest Uniswap V3 best practices, including pool fee settings (commonly 3000 = 0.3%) and `sqrtPriceLimitX96` parameters.

Permit functionality uses ERC-2612. When discussing permit logic, assume tokens follow the standard `permit()` signature and `nonces()` tracking.

The contracts use a modular architecture, with a main `PermitSwapExecutor` contract, `TreasuryManager`, and `SwapHelper`. Code snippets should follow this modular design by abstracting reusable logic into helper contracts where possible.

Security is a priority: always recommend and apply `ReentrancyGuard`, input validation, and deadline enforcement to prevent exploits. All critical functions must be protected against reentrancy.

Use `constructor()` functions with proper initialization, especially for setting addresses such as routers and owners. Suggest using `Ownable` for access control.

Always format Solidity code with 4 spaces indentation, and TypeScript code with 2 spaces indentation, following the project’s style.

Avoid referencing external files like `styleguide.md`. Instead, follow the patterns provided in the README and contracts.

When uncertain, prefer code clarity and explicitness over gas optimization unless otherwise specified.
