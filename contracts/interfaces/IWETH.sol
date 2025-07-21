// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Interface for WETH (Wrapped ETH) contract
interface IWETH {
    /// @notice Withdraw ETH from WETH
    /// @param amount Amount of WETH to withdraw
    function withdraw(uint256 amount) external;
}