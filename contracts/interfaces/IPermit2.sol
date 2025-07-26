// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IPermit2
/// @dev Interface for Permit2 contract to handle token approvals
interface IPermit2 {
    /// @notice Executes a permit2 transfer with the given parameters
    /// @param token The address of the token to approve
    /// @param spender The address that will spend the tokens
    /// @param amount The amount of tokens to approve
    /// @param expiration The timestamp until which the approval is valid
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;
}
