//SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.9.0;

contract Deposit {
    receive() external payable {}

    fallback() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function sendEther() public payable {
        uint x;
        x++;
    }
}
