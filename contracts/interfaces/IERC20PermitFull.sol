// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

/// @title ERC20 token with EIP-2612 permit functionality
/// @notice Interface that combines standard ERC-20 functionality with EIP-2612 permit
/// @dev This interface extends both IERC20 and IERC20Permit to provide a complete
///      token interface that supports gasless approvals via cryptographic signatures
interface IERC20PermitFull is IERC20, IERC20Permit {}