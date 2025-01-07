// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract CircuitBreaker {
    event Stop();

    bool public live;

    constructor() {
        live = true;
    }

    modifier notStopped() {
        require(live, "not live");
        _;
    }

    function _stop() internal {
        live = false;
        emit Stop();
    }
}