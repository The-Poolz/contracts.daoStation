// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @title Mock WETH (Wrapped Ether) Contract
/// @notice A test implementation of WETH with EIP-2612 permit support
/// @dev Provides functionality to wrap ETH into ERC-20 tokens and unwrap back to ETH
///      Used for testing purposes and includes permit functionality for gasless approvals
contract MockWETH9 is ERC20Permit {
    /// @notice Emitted when ETH is deposited and WETH tokens are minted
    /// @param dst The address that received the newly minted WETH tokens
    /// @param wad The amount of ETH deposited (and WETH minted)
    event Deposit(address indexed dst, uint wad);
    
    /// @notice Emitted when WETH tokens are burned and ETH is withdrawn
    /// @param src The address that burned WETH tokens to receive ETH
    /// @param wad The amount of WETH burned (and ETH withdrawn)
    event Withdrawal(address indexed src, uint wad);

    /// @notice Creates a new mock WETH contract
    /// @dev Initializes the ERC20Permit token with "Wrapped Ether" name and "WETH" symbol
    constructor() ERC20Permit("Wrapped Ether") ERC20("Wrapped Ether", "WETH") {}

    /// @notice Receives ETH and automatically wraps it into WETH tokens
    /// @dev Called when ETH is sent directly to the contract address
    receive() external payable {
        deposit();
    }

    /// @notice Deposits ETH and mints equivalent WETH tokens to the caller
    /// @dev Mints WETH tokens equal to the amount of ETH sent with the transaction
    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Burns WETH tokens and withdraws equivalent ETH to the caller
    /// @dev Burns the specified amount of WETH tokens from caller and sends equivalent ETH
    /// @param wad The amount of WETH tokens to burn and ETH to withdraw
    function withdraw(uint256 wad) public {
        require(balanceOf(msg.sender) >= wad, "WETH: insufficient balance");
        _burn(msg.sender, wad);
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    /// @notice Returns the number of decimal places for WETH
    /// @dev WETH uses 18 decimals to match ETH precision
    /// @return The number of decimal places (always 18 for WETH)
    function decimals() public pure override returns (uint8) {
        return 18;
    }
}
