// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/Errors.sol";
import "./common/Modifiers.sol";

/**
 * @title TreasuryManager
 * @notice Manages treasury funds and fee distribution for the DAO Station contracts
 * @dev Abstract contract that handles ETH distribution between users, maintainers, and treasury.
 *      Provides configurable fee percentages and treasury withdrawal functionality.
 *      Uses basis points for fee calculations (150 = 1.5%).
 */
abstract contract TreasuryManager is Ownable, ReentrancyGuard, Modifiers {
    /// @notice Fee percentage for maintainers in basis points (150 = 1.5%)
    /// @dev Default is 150 basis points (1.5%), maximum allowed is 500 basis points (5%)
    uint256 public maintainerFeePercent = 150; // 1.5% default
    
    /// @notice Fee percentage for treasury in basis points (150 = 1.5%)
    /// @dev Default is 150 basis points (1.5%), maximum allowed is 500 basis points (5%)
    uint256 public treasuryFeePercent = 150;   // 1.5% default
    
    /// @notice Maximum fee limit in basis points (500 = 5% each)
    /// @dev Prevents owner from setting excessive fees that would be unfair to users
    uint256 public constant MAX_FEE_PERCENT = 500;
    
    /// @notice Emitted when treasury funds are withdrawn
    /// @param recipient The address that received the withdrawn funds
    /// @param amount The amount of ETH withdrawn
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);
    
    /// @notice Emitted when fee percentages are updated
    /// @param maintainerFee The new maintainer fee percentage in basis points
    /// @param treasuryFee The new treasury fee percentage in basis points
    event FeeUpdated(uint256 maintainerFee, uint256 treasuryFee);

    /// @notice Distributes ETH to maintainer and user, keeps treasury fee in contract
    /// @dev Internal function that calculates and distributes fees based on current fee percentages
    /// @param ethBalance The total amount of ETH to distribute
    /// @param user The address of the user who will receive the majority of ETH
    /// @param maintainer The address of the maintainer who will receive the maintainer fee
    /// @return treasuryFee The amount of ETH kept by the contract as treasury fee
    /// @return userAmount The amount of ETH sent to the user
    /// @return maintainerAmount The amount of ETH sent to the maintainer
    function _distributeETH(uint256 ethBalance, address user, address maintainer) internal returns (uint256 treasuryFee, uint256 userAmount, uint256 maintainerAmount) {
        maintainerAmount = (ethBalance * maintainerFeePercent) / 10000; // Convert basis points to percentage
        treasuryFee = (ethBalance * treasuryFeePercent) / 10000;       // Convert basis points to percentage
        userAmount = ethBalance - maintainerAmount - treasuryFee;      // User gets remainder after fees
        
        payable(maintainer).transfer(maintainerAmount);
        payable(user).transfer(userAmount);
        
        // No event here - will be emitted by main contract with full details
    }

    /// @notice Sets new fee percentages for maintainer and treasury
    /// @dev Only the contract owner can call this function. Fees are capped at MAX_FEE_PERCENT
    /// @param _maintainerFeePercent New maintainer fee in basis points (150 = 1.5%)
    /// @param _treasuryFeePercent New treasury fee in basis points (150 = 1.5%)
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

    /// @notice Withdraws treasury funds to a specified recipient
    /// @dev Only the contract owner can call this function. Uses nonReentrant modifier for security
    /// @param recipient The address that will receive the withdrawn funds
    /// @param amount The amount of ETH to withdraw from the treasury
    function withdrawTreasury(address recipient, uint256 amount) external onlyOwner nonReentrant validRecipient(recipient) sufficientBalance(amount) {
        payable(recipient).transfer(amount);
        emit TreasuryWithdrawal(recipient, amount);
    }

    /// @notice Returns the current treasury balance
    /// @dev The treasury balance is the contract's ETH balance
    /// @return The amount of ETH currently held in the treasury
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
