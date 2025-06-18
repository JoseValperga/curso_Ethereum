// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title GasOptimizationDemo
/// @notice Contrato para demostrar diferencias en consumo de gas en distintas operaciones de escritura y lectura

contract GasOptimizationDemo {
    uint256 public value;
    mapping(address => uint256) public balances;
    uint256[] public numbers;

    event Dummy(uint256 result);

    /// @notice Escribe un valor en storage sin verificar si cambió
    function setValueAlways(uint256 _newValue) external {
        value = _newValue;
    }

    /// @notice Solo escribe en storage si el nuevo valor es diferente
    function setValueIfDifferent(uint256 _newValue) external {
        if (value != _newValue) {
            value = _newValue;
        }
    }

    /// @notice Incrementa el balance del sender directamente en storage (consume gas)
    function incrementBalanceStorage() external {
        balances[msg.sender] += 1;
    }

    /// @notice Usa memoria local para operar y luego guarda el resultado (más eficiente)
    function incrementBalanceWithMemory() external {
        uint256 current = balances[msg.sender];
        current += 1;
        balances[msg.sender] = current;
    }

    /// @notice Agrega 10 elementos a un array en storage (costoso)
    function fillArrayStorage() external {
        for (uint256 i = 0; i < 10; i++) {
            numbers.push(i);
        }
    }

    /// @notice Realiza operaciones en memoria y emite un evento (permite medir gas)
    function operateInMemoryAndEmit() external {
        uint256 total = 0;
        for (uint256 i = 0; i < 10; i++) {
            total += i;
        }
        emit Dummy(total);
    }
}