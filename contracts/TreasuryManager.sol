// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./PermitSwapExecutorState.sol";

/**
 * @title TreasuryManager
 * @notice Manages treasury funds and fee distribution for the DAO Station contracts
 * @dev Abstract contract that handles ETH distribution between users, maintainers, and treasury.
 *      Provides configurable static fee amounts in wei and treasury withdrawal functionality.
 *      Uses fixed amounts instead of percentage-based calculations for predictable fees.
 *      State variables are now managed in PermitSwapExecutorState.
 */
abstract contract TreasuryManager is PermitSwapExecutorState {
    /// @notice Distributes ETH to maintainer and user, keeps treasury fee in contract
    /// @dev Internal function that calculates and distributes fixed fees in wei
    /// @param ethBalance The total amount of ETH to distribute
    /// @param user The address of the user who will receive the majority of ETH
    /// @param maintainer The address of the maintainer who will receive their fee
    /// @return treasuryFee The amount of ETH kept by the contract as treasury fee
    /// @return userAmount The amount of ETH sent to the user
    /// @return maintainerAmount The amount of ETH sent to the maintainer
    function _distributeETH(uint256 ethBalance, address user, address maintainer) internal returns (uint256 treasuryFee, uint256 userAmount, uint256 maintainerAmount) {
        maintainerAmount = maintainerFeeWei;
        treasuryFee = treasuryFeeWei;
        
        // Ensure we have enough ETH to cover the fees
        if (ethBalance < maintainerAmount + treasuryFee) {
            revert Errors.InsufficientBalance();
        }
        
        userAmount = ethBalance - maintainerAmount - treasuryFee;      // User gets remainder after fees

        payable(maintainer).transfer(maintainerAmount);
        payable(user).transfer(userAmount);
        
        // No event here - will be emitted by main contract with full details
    }

    /// @notice Sets new fixed fees in wei for maintainer and treasury
    /// @dev Only the contract owner can call this function. Fees are capped at MAX_FEE_WEI
    /// @param _maintainerFeeWei New maintainer fee in wei
    /// @param _treasuryFeeWei New treasury fee in wei
    function setFees(uint256 _maintainerFeeWei, uint256 _treasuryFeeWei) external override onlyOwner {
        if (_maintainerFeeWei > MAX_FEE_WEI) {
            revert Errors.MaintainerFeeTooHigh();
        }
        if (_treasuryFeeWei > MAX_FEE_WEI) {
            revert Errors.TreasuryFeeTooHigh();
        }
        
        maintainerFeeWei = _maintainerFeeWei;
        treasuryFeeWei = _treasuryFeeWei;
        
        emit FeeUpdated(_maintainerFeeWei, _treasuryFeeWei);
    }

    /// @notice Withdraws treasury funds to a specified recipient
    /// @dev Only the contract owner can call this function. Uses nonReentrant modifier for security
    /// @param recipient The address that will receive the withdrawn funds
    /// @param amount The amount of ETH to withdraw from the treasury
    function withdrawTreasury(address recipient, uint256 amount) external override onlyOwner nonReentrant validRecipient(recipient) sufficientBalance(amount) {
        payable(recipient).transfer(amount);
        emit TreasuryWithdrawal(recipient, amount);
    }
}
