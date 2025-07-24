// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IUniversalRouter.sol";

/// @title Mock Universal Router
/// @notice A simplified mock implementation of Uniswap's Universal Router for testing
/// @dev Provides basic swap functionality with 1:1 exchange rate for simplicity
///      WARNING: This is for testing only and should never be used in production
contract MockUniversalRouter is IUniversalRouter {
    /// @notice The address of the WETH token this router uses
    /// @dev Set during construction
    address public immutable WETH;
    
    /// @notice Fixed exchange rate used for all swaps (1:1 for simplicity)
    /// @dev In a real router, this would be determined by pool prices and liquidity
    uint256 public fixedPrice = 1 ether; // 1:1 for simplicity

    /// @notice Creates a new mock Universal Router
    /// @dev Sets the WETH address that will be used for all WETH-related operations
    /// @param _weth The address of the WETH token contract
    constructor(address _weth) {
        WETH = _weth;
    }

    /// @notice Executes encoded commands along with provided inputs
    /// @dev Simplified implementation that only handles V3_SWAP_EXACT_IN (0x00) command
    /// @param commands A set of concatenated commands, each 1 byte in length
    /// @param inputs An array of byte strings containing abi encoded inputs for each command
    /// @param deadline The deadline by which the transaction must be executed
    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline) external payable override {
        require(block.timestamp <= deadline, "Transaction deadline expired");
        require(commands.length > 0, "No commands provided");
        require(commands.length == inputs.length, "Commands and inputs length mismatch");
        
        for (uint256 i = 0; i < commands.length; i++) {
            uint8 command = uint8(commands[i]);
            
            // Only handle V3_SWAP_EXACT_IN command (0x00)
            if (command == 0x00) {
                _executeV3SwapExactIn(inputs[i]);
            } else {
                revert("Unsupported command in mock");
            }
        }
    }
    
    /// @notice Executes a mock V3 exact input swap with 1:1 exchange rate
    /// @dev Simplified swap implementation for testing
    /// @param input The encoded input parameters for the swap
    function _executeV3SwapExactIn(bytes calldata input) internal {
        // Decode the input parameters
        (address recipient, uint256 amountIn, uint256 amountOutMin, bytes memory path, bool payerIsUser) = 
            abi.decode(input, (address, uint256, uint256, bytes, bool));
        
        require(!payerIsUser, "PayerIsUser must be false for this mock");
        
        // Decode the path to get tokenIn and tokenOut
        // Path format: tokenIn (20 bytes) + fee (3 bytes) + tokenOut (20 bytes)
        require(path.length >= 43, "Invalid path length");
        
        address tokenIn;
        address tokenOut;
        assembly {
            tokenIn := div(mload(add(path, 32)), 0x1000000000000000000000000)
            tokenOut := div(mload(add(path, 55)), 0x1000000000000000000000000)
        }
        
        // Transfer input token from msg.sender (the contract calling this)
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        
        // Calculate output amount (1:1 for simplicity)
        uint256 amountOut = amountIn;
        require(amountOut >= amountOutMin, "Insufficient output amount");
        
        // Transfer output token to recipient
        require(IERC20(tokenOut).transfer(recipient, amountOut), "Output token transfer failed");
    }
}