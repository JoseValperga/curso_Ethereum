//SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

contract A {
    string[] public cities = ["Tokyo", "New York", "Moscow"];

    function f_memory() public {
        string[] memory s1 = cities;
        s1[0] = "Tucuman";
    }

    function f_storage() public {
        string[] storage s1 = cities;
        s1[0] = "Tucuman";
    }
}
/*
La funcion f_memory trabaja sobre una copia de la variable de estado, llamada s1, no la cambia
la funcion f_storage trabaja sobre la variable de estado pues s1 es una referencia y la cambia
*/