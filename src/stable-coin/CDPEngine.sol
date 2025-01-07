// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {Auth} from "src/lib/Auth.sol";
import {CircuitBreaker} from "src/lib/CircuitBreaker.sol";
import {Math} from "src/lib/Math.sol";

contract CDPEngine is Auth, CircuitBreaker {
    mapping (bytes32 collateralType => mapping (address user => uint balance)) public gem;

    function modifyCollateralBalance(bytes32 colType, address user, int256 wad) external auth {
        gem[colType][user] = Math.add(gem[colType][user], wad);
    }    
}