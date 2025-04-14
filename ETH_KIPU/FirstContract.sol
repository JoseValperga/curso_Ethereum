// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title SimpleStorage
 * @dev Un contrato sencillo que permite almacenar, actualizar y leer un número entero.
 *      Incluye un constructor para inicializar el valor almacenado.
 */
contract SimpleStorage {

    // @dev Variable de estado para almacenar un número entero.
    uint256 private storedValue;

    /**
     * @notice Constructor que inicializa el valor almacenado.
     * @dev Se ejecuta una sola vez, al momento de desplegar el contrato.
     * @param _initialValue El valor inicial que se desea almacenar en `storedValue`.
     */
    constructor(uint256 _initialValue) {
        storedValue = _initialValue;
    }

    /**
     * @notice Almacena un valor entero en la variable de estado `storedValue`.
     * @dev La función es pública y puede ser llamada por cualquier usuario.
     * @param _value El valor entero que se desea almacenar.
     */
    function set(uint256 _value) public {
        storedValue = _value;
    }

    /**
     * @notice Lee el valor almacenado en `storedValue`.
     * @dev Función de tipo `view`, ya que no modifica el estado del contrato.
     * @return El valor almacenado en la variable `storedValue`.
     */
    function get() public view returns (uint256) {
        return storedValue;
    }
}