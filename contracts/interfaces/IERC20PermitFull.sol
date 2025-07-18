// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

/// @notice ERC20 token with EIP-2612 permit functionality
interface IERC20PermitFull is IERC20, IERC20Permit {}