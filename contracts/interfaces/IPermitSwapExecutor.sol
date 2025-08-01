// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IPermitSwapExecutor
 * @notice Interface for the PermitSwapExecutor contract with all events consolidated
 * @dev Contains all events from PermitSwapExecutor, TreasuryManager, and SwapHelper contracts
 *      as well as function signatures for the main contract functionality
 */
interface IPermitSwapExecutor {
    /// @notice Emitted when a maintainer's authorization status is updated
    /// @param maintainer The address of the maintainer
    /// @param allowed Whether the maintainer is now authorized
    event MaintainerSet(address indexed maintainer, bool allowed);
    
    /// @notice Emitted when a swap is successfully executed
    /// @param user The original token owner who signed the permit
    /// @param tokenIn The input token that was swapped
    /// @param amountIn The amount of input tokens swapped
    /// @param ethOut The total amount of ETH received from the swap
    /// @param userAmount The amount of ETH sent to the user (remaining after fees)
    /// @param maintainerAmount The amount of ETH sent to the maintainer (fixed fee in wei)
    /// @param treasuryAmount The amount of ETH kept by the contract treasury (fixed fee in wei)
    /// @param data The arbitrary bytes data sent with the swap
    /// @param maintainer The address of the maintainer who executed the swap
    event SwapExecuted(
        address indexed user,
        address indexed tokenIn,
        uint amountIn,
        uint ethOut,
        uint userAmount,
        uint maintainerAmount,
        uint treasuryAmount,
        bytes data,
        address maintainer
    );

    /// @notice Emitted when treasury funds are withdrawn
    /// @param recipient The address that received the withdrawn funds
    /// @param amount The amount of ETH withdrawn
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);
    
    /// @notice Emitted when maintainer fee amount is updated
    /// @param maintainerFee The new maintainer fee amount in wei
    event MaintainerFeeUpdated(uint256 maintainerFee);
    
    /// @notice Emitted when treasury fee amount is updated
    /// @param treasuryFee The new treasury fee amount in wei
    event TreasuryFeeUpdated(uint256 treasuryFee);

    /// @notice Sets the authorization status for a maintainer
    /// @param maintainer The address of the maintainer to update
    /// @param allowed Whether the maintainer should be authorized (true) or not (false)
    function setMaintainer(address maintainer, bool allowed) external;

    /// @notice Executes a complete permit-based token swap to ETH with fee distribution
    /// @param tokenIn The address of the ERC-20 token to swap (must support ERC-2612 permit)
    /// @param commands The encoded commands for UniversalRouter execution
    /// @param inputs The encoded inputs array corresponding to the commands
    /// @param user The address of the token owner who signed the permit
    /// @param data Arbitrary bytes data to be included with the swap
    /// @param deadline The expiration timestamp for the permit signature
    /// @param v The recovery byte of the permit signature
    /// @param r Half of the ECDSA permit signature pair
    /// @param s Half of the ECDSA permit signature pair
    function executeSwap(
        address tokenIn,
        bytes calldata commands,
        bytes[] calldata inputs,
        address user,
        bytes calldata data,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice Sets new fixed maintainer fee in wei
    /// @param _maintainerFeeWei New maintainer fee in wei
    function setMaintainerFee(uint256 _maintainerFeeWei) external;

    /// @notice Sets new fixed treasury fee in wei
    /// @param _treasuryFeeWei New treasury fee in wei
    function setTreasuryFee(uint256 _treasuryFeeWei) external;

    /// @notice Withdraws treasury funds to a specified recipient
    /// @param recipient The address that will receive the withdrawn funds
    /// @param amount The amount of ETH to withdraw from the treasury
    function withdrawTreasury(address recipient, uint256 amount) external;

    /// @notice Returns the current treasury balance
    /// @return The amount of ETH currently held in the treasury
    function getTreasuryBalance() external view returns (uint256);

    /// @notice Validates that a permit signature was signed by the specified user
    /// @param user The address that should have signed the permit
    /// @param spender The address authorized to spend tokens (should be the contract address)
    /// @param amountIn The amount authorized to spend
    /// @param deadline The expiration timestamp for the permit
    /// @param nonce The current nonce for the user (passed from outside to maintain purity)
    /// @param domainSeparator The domain separator for the token (passed from outside to maintain purity)
    /// @param v The recovery byte of the permit signature
    /// @param r Half of the ECDSA permit signature pair  
    /// @param s Half of the ECDSA permit signature pair
    /// @return isValid Whether the signature is valid for the given parameters
    function isValidSignature(
        address user,
        address spender,
        uint256 amountIn,
        uint256 deadline,
        uint256 nonce,
        bytes32 domainSeparator,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external pure returns (bool isValid);

    /// @notice Mapping to track authorized maintainers who can execute swaps
    function isMaintainer(address maintainer) external view returns (bool);

    /// @notice Fixed fee for maintainers in wei
    function maintainerFeeWei() external view returns (uint256);
    
    /// @notice Fixed fee for treasury in wei
    function treasuryFeeWei() external view returns (uint256);
    
    /// @notice Maximum fee limit in wei
    function MAX_FEE_WEI() external view returns (uint256);

    /// @notice The address of the Uniswap Universal Router contract
    function universalRouter() external view returns (address);
    
    /// @notice The address of the WETH (Wrapped Ether) contract
    function WETH() external view returns (address);
}