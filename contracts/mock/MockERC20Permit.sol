// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @title Mock ERC20 Token with Permit Functionality
/// @notice A test implementation of an ERC-20 token with EIP-2612 permit support
/// @dev Used for testing purposes. Extends OpenZeppelin's ERC20Permit with custom decimals and minting
contract MockERC20Permit is ERC20Permit {
    /// @notice The number of decimal places for this token
    /// @dev Immutable value set during contract construction
    uint8 private immutable _customDecimals;

    /// @notice Creates a new mock ERC-20 token with permit functionality
    /// @dev Initializes the token with custom name, symbol, and decimals
    /// @param name The name of the token (e.g., "Mock Token")
    /// @param symbol The symbol of the token (e.g., "MOCK")
    /// @param decimals_ The number of decimal places for the token (e.g., 18)
    constructor(string memory name, string memory symbol, uint8 decimals_) ERC20Permit(name) ERC20(name, symbol) {
        _customDecimals = decimals_;
    }

    /// @notice Mints new tokens to a specified address
    /// @dev Public function that allows anyone to mint tokens for testing purposes
    /// @param to The address that will receive the newly minted tokens
    /// @param amount The amount of tokens to mint (in the token's base unit)
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    /// @notice Returns the number of decimal places for this token
    /// @dev Overrides the default ERC20 decimals function to return custom value
    /// @return The number of decimal places
    function decimals() public view override returns (uint8) {
        return _customDecimals;
    }
}
