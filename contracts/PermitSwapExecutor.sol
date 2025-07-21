// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TreasuryManager.sol";
import "./SwapHelper.sol";
import "./interfaces/Errors.sol";

/**
 * @title PermitSwapExecutor
 * @notice A secure and modular smart contract that enables gasless token swaps using ERC-2612 permit
 * @dev Main contract for executing permit-based token swaps to ETH with fee distribution.
 *      Uses Uniswap integration and reward distribution all in a single atomic transaction.
 *      Only approved maintainers can execute swap logic on behalf of users.
 */
contract PermitSwapExecutor is TreasuryManager, SwapHelper {
    /// @notice Mapping to track authorized maintainers who can execute swaps
    mapping(address => bool) public isMaintainer;

    /// @notice Emitted when a maintainer's authorization status is updated
    /// @param maintainer The address of the maintainer
    /// @param allowed Whether the maintainer is now authorized
    event MaintainerSet(address indexed maintainer, bool allowed);
    
    /// @notice Emitted when a swap is successfully executed
    /// @param user The original token owner who signed the permit
    /// @param tokenIn The input token that was swapped
    /// @param amountIn The amount of input tokens swapped
    /// @param ethOut The total amount of ETH received from the swap
    /// @param userAmount The amount of ETH sent to the user (97% by default)
    /// @param maintainerAmount The amount of ETH sent to the maintainer (1.5% by default)
    /// @param treasuryAmount The amount of ETH kept by the contract treasury (1.5% by default)
    /// @param referrer The referrer address (currently unused but reserved for future use)
    /// @param maintainer The address of the maintainer who executed the swap
    event SwapExecuted(
        address indexed user,
        address indexed tokenIn,
        uint amountIn,
        uint ethOut,
        uint userAmount,
        uint maintainerAmount,
        uint treasuryAmount,
        address referrer,
        address maintainer
    );

    /// @notice Modifier to restrict function access to authorized maintainers only
    /// @dev Reverts with NotMaintainer error if the caller is not an authorized maintainer
    modifier onlyMaintainer() {
        if (!isMaintainer[msg.sender]) {
            revert Errors.NotMaintainer();
        }
        _;
    }

    /// @notice Initializes the PermitSwapExecutor contract
    /// @dev Calls parent constructors for TreasuryManager and SwapHelper initialization
    /// @param _uniswapRouter The address of the Uniswap V3 SwapRouter contract
    /// @param initialOwner The address that will be set as the contract owner
    constructor(address _uniswapRouter, address initialOwner) 
        TreasuryManager()
        SwapHelper(_uniswapRouter)
        Ownable(initialOwner) 
    {
        // All validation is done in parent constructors
    }

    /// @notice Sets the authorization status for a maintainer
    /// @dev Only the contract owner can call this function
    /// @param maintainer The address of the maintainer to update
    /// @param allowed Whether the maintainer should be authorized (true) or not (false)
    function setMaintainer(address maintainer, bool allowed) external onlyOwner {
        isMaintainer[maintainer] = allowed;
        emit MaintainerSet(maintainer, allowed);
    }

    /// @notice Executes a complete permit-based token swap to ETH with fee distribution
    /// @dev Performs permit, token transfer, swap (if needed), WETH unwrapping, and ETH distribution in one atomic transaction
    /// @param tokenIn The address of the ERC-20 token to swap (must support ERC-2612 permit)
    /// @param poolFee The Uniswap V3 pool fee for the swap (e.g., 3000 for 0.3%)
    /// @param amountIn The amount of input tokens to swap
    /// @param amountOutMin The minimum amount of WETH to receive from the swap (slippage protection)
    /// @param sqrtPriceLimitX96 The price limit for the swap in sqrt(price) * 2^96 format (0 = no limit)
    /// @param user The address of the token owner who signed the permit
    /// @param referrer The referrer address (reserved for future use, currently unused)
    /// @param deadline The expiration timestamp for the permit signature
    /// @param v The recovery byte of the permit signature
    /// @param r Half of the ECDSA permit signature pair
    /// @param s Half of the ECDSA permit signature pair
    function executeSwap(
        address tokenIn,
        uint24 poolFee,
        uint amountIn,
        uint amountOutMin,
        uint160 sqrtPriceLimitX96,
        address user,
        address referrer,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyMaintainer nonReentrant {
        if (user == address(0)) {
            revert Errors.ZeroUser();
        }
        if (block.timestamp > deadline) {
            revert Errors.Expired();
        }
        
        // prepare token: permit, transfer, and approve        
        _prepareToken(tokenIn, user, amountIn, deadline, v, r, s);
        
        uint wethReceived;
        // If input token is WETH, skip swap
        if (tokenIn == WETH) {
            wethReceived = amountIn;
        } else {
            // Swap to WETH (Uniswap V3)
            wethReceived = _swapToWETH(tokenIn, poolFee, amountIn, amountOutMin, sqrtPriceLimitX96, deadline);
        }
        
        // Unwrap WETH to ETH
        _unwrapWETH(wethReceived);
        
        // Distribute ETH (configurable fees to maintainer and treasury, rest to user)
        (uint256 treasuryFee, uint256 userAmt, uint256 maintainerAmt) = _distributeETH(wethReceived, user, msg.sender);
        
        emit SwapExecuted(user, tokenIn, amountIn, wethReceived, userAmt, maintainerAmt, treasuryFee, referrer, msg.sender);
    }

    /// @notice Receives ETH payments (required for WETH unwrapping)
    /// @dev This function is called when the contract receives ETH via transfer() or send()
    receive() external payable {}
    
    /// @notice Fallback function to receive ETH payments
    /// @dev This function is called when the contract receives ETH with non-matching function calls
    fallback() external payable {}
}
