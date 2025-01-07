// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {Auth} from "src/lib/Auth.sol";
import {CircuitBreaker} from "src/lib/CircuitBreaker.sol";
import {Math} from "src/lib/Math.sol";

// Vat
contract CDPEngine is Auth, CircuitBreaker {
    // Ilk
    struct Collateral {
        // Art
        uint256 debt; // Total Normalised Debt     [wad]
        // rate
        uint256 rateAcc; // Accumulated Rates         [ray]
        // spot
        uint256 spot; // Price with Safety Margin  [ray]
        // line
        uint256 maxDebt; // Debt Ceiling              [rad]
        uint256 minDebt; // Urn Debt Floor            [rad]
    }

    // Urn - Vault
    struct Position {
        uint256 collateral; // Locked Collateral  [wad]
        uint256 debt; // Normalised Debt    [wad]
    }

    mapping(bytes32 => Collateral) public collaterals;
    mapping(bytes32 id => mapping(address owner => Position position)) public positions;

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
