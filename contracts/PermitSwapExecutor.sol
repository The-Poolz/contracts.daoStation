// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SwapHelper.sol";

/**
 * @title PermitSwapExecutor
 * @notice A secure and modular smart contract that enables gasless token swaps using ERC-2612 permit
 * @dev Main contract for executing permit-based token swaps to ETH with fee distribution.
 *      Uses Uniswap integration and reward distribution all in a single atomic transaction.
 *      Only approved maintainers can execute swap logic on behalf of users.
 *      Now implements IPermitSwapExecutor interface and inherits from refactored modules.
 */
contract PermitSwapExecutor is TreasuryManager, SwapHelper {
    /// @notice Modifier to restrict function access to authorized maintainers only
    /// @dev Reverts with NotMaintainer error if the caller is not an authorized maintainer
    modifier onlyMaintainer() {
        if (!isMaintainer[msg.sender]) {
            revert Errors.NotMaintainer();
        }
        _;
    }

    /// @notice Initializes states with Universal Router, WETH address, and owner
    /// @dev Sets up the Universal Router address and WETH address for swap operations
    /// @param _universalRouter The address of the Uniswap Universal Router contract
    /// @param _weth The address of the WETH contract
    constructor(address _universalRouter, address _weth, IPermit2 _permit2) 
        Ownable(_msgSender()) 
    {
        if (_universalRouter == address(0)) {
            revert Errors.ZeroRouterAddress();
        }
        if (_weth == address(0)) {
            revert Errors.ZeroWETHAddress();
        }
        if (address(_permit2) == address(0)) {
            revert Errors.ZeroPermit2Address();
        }
        universalRouter = _universalRouter;
        WETH = _weth;
        permit2 = _permit2;
    }

    /// @notice Sets the authorization status for a maintainer
    /// @dev Only the contract owner can call this function
    /// @param maintainer The address of the maintainer to update
    /// @param allowed Whether the maintainer should be authorized (true) or not (false)
    function setMaintainer(address maintainer, bool allowed) external override onlyOwner {
        isMaintainer[maintainer] = allowed;
        emit MaintainerSet(maintainer, allowed);
    }

    /// @notice Executes a complete permit-based token swap to ETH with fee distribution
    /// @dev Performs permit, token transfer, swap (if needed), WETH unwrapping, and ETH distribution in one atomic transaction
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
    ) external override onlyMaintainer nonReentrant validUser(user) validDeadline(deadline) nonEmptyCommands(commands) nonEmptyInputs(inputs) {
        // Check the first command to determine how to extract amountIn
        uint8 firstCommand = uint8(commands[0]);
        uint256 amountIn;
        bytes memory path;
        
        if (firstCommand == 0x0c) {
            // UNWRAP_WETH command: (address recipient, uint256 amount)
            (, amountIn) = abi.decode(inputs[0], (address, uint256));
        } else {
            // V3_SWAP_EXACT_IN command: (address recipient, uint256 amountIn, uint256 amountOutMin, bytes path, bool payerIsUser)
            (, amountIn, , path, ) = abi.decode(inputs[0], (address, uint256, uint256, bytes, bool));
        }
        
        // prepare token: permit, transfer, and approve        
        _prepareToken(tokenIn, user, amountIn, deadline, v, r, s);
        
        uint wethReceived;
        // If input token is WETH, execute unwrap command directly
        if (tokenIn == WETH) {
            wethReceived = _swapToWETH(commands, inputs, deadline);
        } else {
            // For non-WETH tokens, extract path for validation
            _validateInputParams(path);
            wethReceived = _swapToWETH(commands, inputs, deadline);
        }
        
        // Distribute ETH (configurable fees to maintainer and treasury, rest to user)
        (uint256 treasuryFee, uint256 userAmt, uint256 maintainerAmt) = _distributeETH(wethReceived, user, msg.sender);
        
        emit SwapExecuted(user, tokenIn, amountIn, wethReceived, userAmt, maintainerAmt, treasuryFee, data, msg.sender);
    }

    /// @notice Receives ETH payments (required for WETH unwrapping)
    /// @dev This function is called when the contract receives ETH via transfer() or send()
    receive() external payable {}
    
    /// @notice Fallback function to receive ETH payments
    /// @dev This function is called when the contract receives ETH with non-matching function calls
    fallback() external payable {}
}
