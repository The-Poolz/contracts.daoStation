// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IUniversalRouter.sol";
import "./interfaces/IPermitSwapExecutor.sol";
import "./common/Modifiers.sol";

/**
 * @title PermitSwapExecutorState
 * @notice Storage contract containing state variables and view functions for DAO Station contracts
 * @dev Abstract contract that centralizes state management and provides view functions.
 *      Contains state variables from TreasuryManager, SwapHelper, and PermitSwapExecutor.
 *      Provides a single source of truth for contract state.
 */
abstract contract PermitSwapExecutorState is
    Ownable,
    ReentrancyGuard,
    Modifiers,
    IPermitSwapExecutor
{
    /// @notice Mapping to track authorized maintainers who can execute swaps
    mapping(address => bool) public isMaintainer;

    /// @notice Fee percentage for maintainers in basis points (150 = 1.5%)
    /// @dev Default is 150 basis points (1.5%), maximum allowed is 500 basis points (5%)
    uint256 public maintainerFeePercent = 150; // 1.5% default

    /// @notice Fee percentage for treasury in basis points (150 = 1.5%)
    /// @dev Default is 150 basis points (1.5%), maximum allowed is 500 basis points (5%)
    uint256 public treasuryFeePercent = 150; // 1.5% default

    /// @notice Maximum fee limit in basis points (500 = 5% each)
    /// @dev Prevents owner from setting excessive fees that would be unfair to users
    uint256 public constant MAX_FEE_PERCENT = 500;

    /// @notice The address of the Uniswap Universal Router contract
    /// @dev Used for executing token swaps on Uniswap v2, v3, and v4 protocols
    address public immutable universalRouter;

    /// @notice The address of the WETH (Wrapped Ether) contract
    /// @dev Retrieved from the Uniswap router and used as the target token for swaps
    address public immutable WETH;

    /// @notice Returns the current treasury balance
    /// @dev The treasury balance is the contract's ETH balance
    /// @return The amount of ETH currently held in the treasury
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Validates that a permit signature was signed by the specified user
    /// @dev This is a pure function that reconstructs the ERC-2612 permit hash and recovers the signer address
    /// @param user The address that should have signed the permit
    /// @param spender The address authorized to spend tokens (should be the contract address)
    /// @param amountIn The amount authorized to spend
    /// @param deadline The expiration timestamp for the permit
    /// @param nonce The current nonce for the user (passed from outside to maintain purity)
    /// @param domainSeparator The domain separator for the token (passed from outside to maintain purity)
    /// @param v The recovery byte of the permit signature
    /// @param r Half of the ECDSA permit signature pair
    /// @param s Half of the ECDSA permit signature pair
    /// @return isValid Whether the signature is valid for the given parameters
    function isValidSignature(
        address user,
        address spender,
        uint256 amountIn,
        uint256 deadline,
        uint256 nonce,
        bytes32 domainSeparator,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (bool isValid) {
        // Reconstruct the ERC-2612 permit hash
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                ),
                user,
                spender,
                amountIn,
                nonce,
                deadline
            )
        );

        // Create the final hash according to EIP-712
        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        // Recover the signer address from the signature
        address recoveredSigner = ECDSA.recover(hash, v, r, s);

        // Return whether the recovered signer matches the provided user address
        return recoveredSigner == user;
    }
}
