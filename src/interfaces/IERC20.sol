// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

interface IERC20 {
    function balanceOf(address guy) external view returns (uint256);
    function approve(address guy, uint256 wad) external;
}