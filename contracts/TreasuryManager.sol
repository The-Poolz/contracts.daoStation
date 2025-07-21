// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/Errors.sol";

/**
 * @title TreasuryManager
 * @dev Manages treasury funds and fee distribution
 */
abstract contract TreasuryManager is Ownable, ReentrancyGuard {
    // Fee percentages (in basis points: 150 = 1.5%)
    uint256 public maintainerFeePercent = 150; // 1.5% default
    uint256 public treasuryFeePercent = 150;   // 1.5% default
    
    // Maximum fee limit (5% each = 500 basis points)
    uint256 public constant MAX_FEE_PERCENT = 500;
    
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);
    event FeeUpdated(uint256 maintainerFee, uint256 treasuryFee);

    /// @dev Distributes ETH to maintainer and user, keeps treasury fee in contract
    function _distributeETH(uint256 ethBalance, address user, address maintainer) internal returns (uint256 treasuryFee, uint256 userAmount, uint256 maintainerAmount) {
        maintainerAmount = (ethBalance * maintainerFeePercent) / 10000; // Convert basis points to percentage
        treasuryFee = (ethBalance * treasuryFeePercent) / 10000;       // Convert basis points to percentage
        userAmount = ethBalance - maintainerAmount - treasuryFee;      // User gets remainder after fees
        
        payable(maintainer).transfer(maintainerAmount);
        payable(user).transfer(userAmount);
        
        // No event here - will be emitted by main contract with full details
    }

    /// @dev Set fee percentages (only owner can call)
    /// @param _maintainerFeePercent Maintainer fee in basis points (150 = 1.5%)
    /// @param _treasuryFeePercent Treasury fee in basis points (150 = 1.5%)
    function setFeePercents(uint256 _maintainerFeePercent, uint256 _treasuryFeePercent) external onlyOwner {
        if (_maintainerFeePercent > MAX_FEE_PERCENT) {
            revert Errors.MaintainerFeeTooHigh();
        }
        if (_treasuryFeePercent > MAX_FEE_PERCENT) {
            revert Errors.TreasuryFeeTooHigh();
        }
        
        maintainerFeePercent = _maintainerFeePercent;
        treasuryFeePercent = _treasuryFeePercent;
        
        emit FeeUpdated(_maintainerFeePercent, _treasuryFeePercent);
    }

    /// @dev Admin function to withdraw treasury funds to any address
    function withdrawTreasury(address recipient, uint256 amount) external onlyOwner nonReentrant {
        if (recipient == address(0)) {
            revert Errors.ZeroRecipientAddress();
        }
        if (amount > address(this).balance) {
            revert Errors.InsufficientBalance();
        }
        payable(recipient).transfer(amount);
        emit TreasuryWithdrawal(recipient, amount);
    }

    /// @dev Get current treasury balance (contract's ETH balance)
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
