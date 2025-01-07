//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Auth} from "src/lib/Auth.sol";
import {CircuitBreaker} from "src/lib/CircuitBreaker.sol";

interface IGem {
    function decimals() external view returns (uint8);
    function transfer(address dst, uint256 wad) external returns (bool);
    function transferFrom(address src, address dst, uint256 wad) external returns (bool);
}

interface ICDPEngine { // Collateralized Debt Position
    function modifyCollateralBalance(bytes32, address, int256) external;
}

contract GemJoin is Auth, CircuitBreaker {
    event Join(address indexed usr, uint256 wad);
    event Exit(address indexed usr, uint256 wad);

    ICDPEngine public cdpEngine;
    bytes32 public collateralType;
    IGem public gem;
    uint8 public decimals;

    constructor(address _cdpEngine, bytes32 _collateralType, address _gem) {
        cdpEngine = ICDPEngine(_cdpEngine);
        collateralType = _collateralType;
        gem = IGem(_gem);
        decimals = gem.decimals();
    }

    function stop() external auth {
        _stop();
    }

    function join(address usr, uint256 wad) external notStopped {
        require(int256(wad) >= 0, "overflow");
        cdpEngine.modifyCollateralBalance(collateralType, usr, int256(wad));
        require(gem.transferFrom(msg.sender, address(this), wad), "failed-transfer");
        emit Join(usr, wad);
    }

    function exit(address usr, uint256 wad) external notStopped {
        require(wad <= 2 ** 255, "overflow");
        cdpEngine.modifyCollateralBalance(collateralType, msg.sender, -int256(wad));
        require(gem.transfer(usr, wad), "GemJoin/failed-transfer");
        emit Exit(usr, wad);
    }
}
