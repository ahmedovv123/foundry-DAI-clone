// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {Auth} from "src/lib/Auth.sol";
import {CircuitBreaker} from "src/lib/CircuitBreaker.sol";

library Math {
    function add(uint x, int y) internal pure returns (uint) {
        // z = x + uint(y);
        // require(y >= 0 || z <= x);
        // require(y <= 0 || z >= x);
        return y >= 0 ? x + uint(y) : x - uint(-y);
    }
}

contract CDPEngine is Auth, CircuitBreaker {
    mapping (bytes32 collateralType => mapping (address user => uint balance)) public gem;

    function modifyCollateralBalance(bytes32 colType, address user, int256 wad) external auth {
        gem[colType][user] = Math.add(gem[colType][user], wad);
    }    
}