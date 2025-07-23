// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IPermitSwapExecutor.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/Errors.sol";
import "./common/Modifiers.sol";

/**
 * @title PermitSwapExecutorStorage
 * @notice Storage contract containing state variables and view functions for DAO Station contracts
 * @dev Abstract contract that centralizes state management and provides view functions.
 *      Contains state variables from TreasuryManager, SwapHelper, and PermitSwapExecutor.
 *      Provides a single source of truth for contract state.
 */
abstract contract PermitSwapExecutorStorage is Ownable, ReentrancyGuard, Modifiers, IPermitSwapExecutor {
    /// @notice Mapping to track authorized maintainers who can execute swaps
    mapping(address => bool) public override isMaintainer;

    /// @notice Fee percentage for maintainers in basis points (150 = 1.5%)
    /// @dev Default is 150 basis points (1.5%), maximum allowed is 500 basis points (5%)
    uint256 public override maintainerFeePercent = 150; // 1.5% default
    
    /// @notice Fee percentage for treasury in basis points (150 = 1.5%)
    /// @dev Default is 150 basis points (1.5%), maximum allowed is 500 basis points (5%)
    uint256 public override treasuryFeePercent = 150;   // 1.5% default
    
    /// @notice Maximum fee limit in basis points (500 = 5% each)
    /// @dev Prevents owner from setting excessive fees that would be unfair to users
    uint256 public constant override MAX_FEE_PERCENT = 500;
    
    /// @notice The address of the Uniswap V3 SwapRouter contract
    /// @dev Used for executing token swaps on Uniswap V3 protocol
    address public immutable override uniswapRouter;
    
    /// @notice The address of the WETH (Wrapped Ether) contract
    /// @dev Retrieved from the Uniswap router and used as the target token for swaps
    address public immutable override WETH;

    /// @notice Initializes the storage contract with Uniswap router and owner
    /// @dev Sets up the router address and retrieves WETH address from it
    /// @param _uniswapRouter The address of the Uniswap V3 SwapRouter contract
    /// @param initialOwner The address that will be set as the contract owner
    constructor(address _uniswapRouter, address initialOwner) Ownable(initialOwner) {
        if (_uniswapRouter == address(0)) {
            revert Errors.ZeroRouterAddress();
        }
        uniswapRouter = _uniswapRouter;
        WETH = ISwapRouter(_uniswapRouter).WETH9();
    }

    /// @notice Returns the current treasury balance
    /// @dev The treasury balance is the contract's ETH balance
    /// @return The amount of ETH currently held in the treasury
    function getTreasuryBalance() external view override returns (uint256) {
        return address(this).balance;
    }

    /// @notice Receives ETH payments (required for WETH unwrapping)
    /// @dev This function is called when the contract receives ETH via transfer() or send()
    receive() external payable {}
    
    /// @notice Fallback function to receive ETH payments
    /// @dev This function is called when the contract receives ETH with non-matching function calls
    fallback() external payable {}
}