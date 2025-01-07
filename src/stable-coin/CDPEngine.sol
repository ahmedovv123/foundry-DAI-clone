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
        // dust
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

    uint256 public sysMaxDebt; // Total Debt Ceiling [rad]

    function init(bytes32 colType) external auth {
        require(collaterals[colType].rateAcc == 0, "Collateral already init");
        collaterals[colType].rateAcc = 10 ** 27; // rad
    }
    // file

    function set(bytes32 key, uint256 val) external auth notStopped {
        if (key == "sysMaxDebt") sysMaxDebt = val;
        else revert("Key not recognized");
    }
    // file

    function set(bytes32 colType, bytes32 key, uint256 val) external auth notStopped {
        if (key == "spot") collaterals[colType].spot = val;
        else if (key == "maxDebt") collaterals[colType].maxDebt = val;
        else if (key == "minDebt") collaterals[colType].minDebt = val;
        else revert("Key not recognized");
    }

    // cage
    function stop() external auth {
        _stop();
    }

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

    uint256 public sysDebt;

    // frob - modify a CDP
    function modifyCdp(
        // i - collateral id
        bytes32 colType,
        // u - address that maps to CDP
        address cdp,
        // v - source of gem
        address gemSrc,
        // w - destination of coin
        address coinDst,
        // dink - delta collateral
        int256 deltaCol,
        // dart - delta debt
        int256 deltaDebt
    ) external notStopped {
        Position memory pos = positions[colType][cdp];
        Collateral memory col = collaterals[colType];
        // ilk has been initialised
        require(col.rateAcc != 0, "collateral not initialized");

        pos.collateral = Math.add(pos.collateral, deltaCol);
        pos.debt = Math.add(pos.debt, deltaDebt);
        col.debt = Math.add(col.debt, deltaDebt);

        // dtab
        int256 deltaCoin = Math.mul(col.rateAcc, deltaDebt);
        // tab
        uint256 coinDebt = col.rateAcc * pos.debt;
        sysDebt = Math.add(sysDebt, deltaCoin);

        // either debt has decreased, or debt ceilings are not exceeded
        require(
            deltaDebt <= 0 || col.debt * col.rateAcc <= col.maxDebt && sysDebt <= sysMaxDebt,
            "Vat/ceiling-exceeded"
        );
        // pos is either less risky than before, or it is safe
        require((deltaDebt <= 0 && deltaCol >= 0) || (coinDebt <= pos.collateral * col.spot), "Vat/not-safe");

        // pos is either more safe, or the owner consents
        require((deltaDebt <= 0 && deltaCol >= 0) || canModifyAccount(cdp, msg.sender), "Vat/not-allowed-u");
        // collateral src consents
        require(deltaCol <= 0 || canModifyAccount(gemSrc, msg.sender), "Vat/not-allowed-v");
        // debt dst consents
        require(deltaDebt >= 0 || canModifyAccount(coinDst, msg.sender), "Vat/not-allowed-w");

        // urn has no debt, or a non-dusty amount
        require(pos.debt == 0 || coinDebt >= col.minDebt, "Vat/dust");

        gem[colType][gemSrc] = Math.sub(gem[colType][gemSrc], deltaCol);
        coin[coinDst] = Math.add(coin[coinDst], deltaCoin);

        positions[colType][cdp] = pos;
        collaterals[colType] = col;
    }
}
