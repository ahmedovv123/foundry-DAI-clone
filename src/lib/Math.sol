// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

uint256 constant WAD = 10 ** 18;
uint256 constant RAY = 10 ** 27;
uint256 constant RAD = 10 ** 45;

library Math {
    function add(uint x, int y) internal pure returns (uint) {
        return y >= 0 ? x + uint(y) : x - uint(-y);
    }
}