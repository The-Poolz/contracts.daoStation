// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../TreasuryManager.sol";

contract TreasuryManagerTest is TreasuryManager {
    
    constructor(address initialOwner) Ownable(initialOwner) {}

    function test_distributeETH(uint256 ethBalance, address user, address maintainer) 
        external 
        returns (uint256 treasuryFee, uint256 userAmount, uint256 maintainerAmount) 
    {
        return _distributeETH(ethBalance, user, maintainer);
    }

    function test_depositETH() external payable {}

    receive() external payable {}
}
