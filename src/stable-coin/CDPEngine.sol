// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {Auth} from "src/lib/Auth.sol";
import {CircuitBreaker} from "src/lib/CircuitBreaker.sol";
import {Math} from "src/lib/Math.sol";

contract CDPEngine is Auth, CircuitBreaker {
    mapping(bytes32 collateralType => mapping(address user => uint256 balance)) public gem;
    mapping(address => uint256) public coin; // [rad]

    mapping(address owner => mapping(address user => bool canModify)) public can;

    // hope
    function allowAccountModification(address usr) external {
        can[msg.sender][usr] = true;
    }

    // nope
    function denyAccountModification(address usr) external {
        can[msg.sender][usr] = false;
    }

    function canModifyAccount(address owner, address usr) internal view returns (bool) {
        return owner == usr || can[owner][usr];
    }

    // move
    function transferCoin(address src, address dst, uint256 rad) external {
        require(canModifyAccount(src, msg.sender), "Vat/not-allowed");
        coin[src] -= rad;
        coin[dst] += rad;
    }

    // slip
    function modifyCollateralBalance(bytes32 colType, address user, int256 wad) external auth {
        gem[colType][user] = Math.add(gem[colType][user], wad);
    }
}
