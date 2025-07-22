// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Errors
 * @dev Custom error definitions for the DAO Station contracts
 */
interface Errors {
    /// @notice Thrown when caller is not an authorized maintainer
    error NotMaintainer();
    
    /// @notice Thrown when user address is zero
    error ZeroUser();
    
    /// @notice Thrown when deadline has expired
    error Expired();
    
    /// @notice Thrown when router address is zero
    error ZeroRouterAddress();
    
    /// @notice Thrown when maintainer fee exceeds maximum allowed
    error MaintainerFeeTooHigh();
    
    /// @notice Thrown when treasury fee exceeds maximum allowed
    error TreasuryFeeTooHigh();
    
    /// @notice Thrown when recipient address is zero
    error ZeroRecipientAddress();
    
    /// @notice Thrown when trying to withdraw more than available balance
    error InsufficientBalance();
    
    /// @notice Thrown when permit signature is invalid
    error InvalidPermitSignature();
}