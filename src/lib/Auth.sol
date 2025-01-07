//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Auth {
    event GrantAuthorization(address indexed usr);
    event DenyAuthorization(address indexed usr);

    // --- Auth ---
    mapping(address => bool) public authorized;

    constructor() {
        authorized[msg.sender] = true;
        emit GrantAuthorization(msg.sender);
    }

    modifier auth() {
        require(authorized[msg.sender], "not authorized");
        _;
    }

    function grantAuth(address usr) external auth {
        authorized[usr] = true;
        emit GrantAuthorization(usr);
    }

    function denyAuth(address usr) external auth {
        authorized[usr] = false;
        emit DenyAuthorization(usr);
    }
}