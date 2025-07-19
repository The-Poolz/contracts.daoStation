// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TreasuryManager
 * @dev Manages treasury funds and fee distribution
 */
abstract contract TreasuryManager is Ownable {
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);

    /// @dev Distributes ETH to maintainer and user, keeps treasury fee in contract
    function _distributeETH(uint256 ethBalance, address user, address maintainer) internal returns (uint256 treasuryFee, uint256 userAmount, uint256 maintainerAmount) {
        uint oneAndHalfPercent = (ethBalance * 15) / 1000; // 1.5%
        treasuryFee = oneAndHalfPercent; // Treasury fee stays in contract
        maintainerAmount = oneAndHalfPercent;
        userAmount = ethBalance - (2 * oneAndHalfPercent); // User gets remainder after 3% total fees
        
        payable(maintainer).transfer(maintainerAmount);
        payable(user).transfer(userAmount);
        
        // No event here - will be emitted by main contract with full details
    }

    /// @dev Admin function to withdraw treasury funds to any address
    function withdrawTreasury(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Zero recipient address");
        require(amount <= address(this).balance, "Insufficient balance");
        payable(recipient).transfer(amount);
        emit TreasuryWithdrawal(recipient, amount);
    }

    /// @dev Get current treasury balance (contract's ETH balance)
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
