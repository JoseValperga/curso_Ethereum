// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract Animal {
    function emitirSonido() public view virtual returns (string memory);
    function alimentarse() public pure virtual returns (string memory) {
        return "Buscando comida";
    }
}

contract Perro is Animal {
    function emitirSonido() public pure override returns (string memory) {
        return "Guau guau!";
    }
    // alimentarse() queda heredada con implementación
}