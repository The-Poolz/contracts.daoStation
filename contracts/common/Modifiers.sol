// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/Errors.sol";

/**
 * @title Modifiers
 * @notice Common modifiers used across DAO Station contracts
 * @dev Provides reusable validation modifiers for enhanced code modularity and consistency
 */
abstract contract Modifiers {
    /// @notice Validates that the user address is not zero
    /// @dev Reverts with ZeroUser error if the user address is zero
    /// @param user The user address to validate
    modifier validUser(address user) {
        if (user == address(0)) {
            revert Errors.ZeroUser();
        }
        _;
    }

    /// @notice Validates that the deadline has not expired
    /// @dev Reverts with Expired error if the current block timestamp exceeds the deadline
    /// @param deadline The deadline timestamp to validate against
    modifier validDeadline(uint deadline) {
        if (block.timestamp > deadline) {
            revert Errors.Expired();
        }
        _;
    }

    /// @notice Validates that the recipient address is not zero
    /// @dev Reverts with ZeroRecipientAddress error if the recipient address is zero
    /// @param recipient The recipient address to validate
    modifier validRecipient(address recipient) {
        if (recipient == address(0)) {
            revert Errors.ZeroRecipientAddress();
        }
        _;
    }

    /// @notice Validates that the contract has sufficient balance for the requested amount
    /// @dev Reverts with InsufficientBalance error if the amount exceeds contract balance
    /// @param amount The amount to validate against contract balance
    modifier sufficientBalance(uint256 amount) {
        if (amount > address(this).balance) {
            revert Errors.InsufficientBalance();
        }
        _;
    }
}