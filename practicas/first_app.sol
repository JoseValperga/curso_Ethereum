//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Counter {
    uint256 public count;

    constructor(uint256 initialValue) {
        count = initialValue;
    }

    function increment() external {
        ++count;
    }

    function decrement() internal {
        --count;
    }

    function get() public view returns (uint256) {
        return count;
    }
}
