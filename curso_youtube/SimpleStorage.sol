//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* tipos de datos
contract SimpleStorage {
    uint256  favoriteNumber = 7;
    int256 favoriteInt = -7;
    bool favoriteBool = true;
    string favoriteString = "hello world";
    address favoriteSAdress = 0xb6219CaB8C0C50474A43Df76572AbE9FC968d5aD;
    bytes8 favoriteBytes = "hello";
}
*/

contract SimpleStorage {
    uint256 public favoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber =_favoriteNumber;
    }
}
