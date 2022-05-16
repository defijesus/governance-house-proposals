// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import "forge-std/stdlib.sol";
import "ds-test/test.sol";

import { IERC20 } from "../../interfaces/IERC20.sol";
import { ILendingPool } from "../../interfaces/ILendingPool.sol";

contract Cycle is DSTest {
    using stdStorage for StdStorage;
    
    StdStorage stdstore;
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    event Deposit(
      address indexed reserve,
      address user,
      address indexed onBehalfOf,
      uint256 amount,
      uint16 indexed referral
    );

    event Borrow(
      address indexed reserve,
      address user,
      address indexed onBehalfOf,
      uint256 amount,
      uint256 borrowRateMode,
      uint256 borrowRate,
      uint16 indexed referral
    );

    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    function fullCycle(IERC20 token, ILendingPool pool, address user) external {
        vm.startPrank(user);
        stdstore
            .target(address(token))
            .sig(token.balanceOf.selector)
            .with_key(user)
            .checked_write(100 ether);

        token.approve(address(pool), 100 ether);
        
        vm.expectEmit(true, true, true, true);
        emit Deposit(address(token), user, user, 100 ether, 0);
        pool.deposit(address(token), 100 ether, user, 0); 

        vm.expectEmit(true, true, true, false);
        emit Borrow(address(token), user, user, 20 ether, 2, 0, 0);
        pool.borrow(address(token), 20 ether, 2, 0, user);
        
        vm.expectEmit(true, true, true, true);
        emit Withdraw(address(token), user, user, 20 ether);
        pool.withdraw(address(token), 20 ether, user);
        vm.stopPrank();
    }
}