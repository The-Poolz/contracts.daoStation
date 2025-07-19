// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../TreasuryManager.sol";

/**
 * @title TreasuryManagerTest
 * @dev Test contract that exposes TreasuryManager internal functions as public
 * @notice This contract should NEVER be deployed to mainnet - only for testing!
 */
contract TreasuryManagerTest is TreasuryManager {
    
    constructor(address initialOwner) Ownable(initialOwner) {
        // Simple constructor - no additional setup needed
    }

    /// @dev Test function to expose _distributeETH
    function test_distributeETH(uint256 ethBalance, address user, address maintainer) 
        external 
        returns (uint256 treasuryFee, uint256 userAmount, uint256 maintainerAmount) 
    {
        return _distributeETH(ethBalance, user, maintainer);
    }

    /// @dev Allow receiving ETH for testing
    receive() external payable {}
}
