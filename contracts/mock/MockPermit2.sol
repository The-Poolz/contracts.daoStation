// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IPermit2.sol";

/**
 * @title MockPermit2
 * @notice Mock implementation of Permit2 for testing purposes
 * @dev Simple mock that just stores approval data without complex logic
 */
contract MockPermit2 is IPermit2 {
    mapping(address => mapping(address => mapping(address => uint256))) public allowances;
    
    /// @notice Mock approve function that stores the approval
    /// @param token The token address
    /// @param spender The spender address  
    /// @param amount The amount to approve
    function approve(address token, address spender, uint160 amount, uint48 /* expiration */) external override {
        allowances[msg.sender][token][spender] = amount;
    }
    
    /// @notice Helper function to check allowances (for testing)
    /// @param owner The owner address
    /// @param token The token address
    /// @param spender The spender address
    /// @return The approved amount
    function getAllowance(address owner, address token, address spender) external view returns (uint256) {
        return allowances[owner][token][spender];
    }
}
