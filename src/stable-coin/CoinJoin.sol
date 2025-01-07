// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {Auth} from "src/lib/Auth.sol";
import {CircuitBreaker} from "src/lib/CircuitBreaker.sol";
import {RAY} from "src/lib/Math.sol";

interface ICoin {
    function mint(address, uint256) external;
    function burn(address, uint256) external;
}

interface ICDPEngine {
    function transferCoin(address src, address dst, uint256 wad) external;
}

contract CoinJoin is Auth, CircuitBreaker {
    // vat
    ICDPEngine public cdpEngine; // CDP Engine
    // dai
    ICoin public coin; // Stablecoin Token

    // Events
    event Join(address indexed usr, uint256 wad);
    event Exit(address indexed usr, uint256 wad);

    constructor(address _cdpEngine, address _coin) {
        cdpEngine = ICDPEngine(_cdpEngine);
        coin = ICoin(_coin);
    }

    function stop() external auth {
        _stop();
    }

    function join(address usr, uint256 wad) external {
        // vat.move
        cdpEngine.transferCoin(address(this), usr, RAY * wad);
        coin.burn(msg.sender, wad);
        emit Join(usr, wad);
    }

    function exit(address usr, uint256 wad) external notStopped {
        // vat.move
        cdpEngine.transferCoin(msg.sender, address(this), RAY * wad);
        coin.mint(usr, wad);
        emit Exit(usr, wad);
    }
}
