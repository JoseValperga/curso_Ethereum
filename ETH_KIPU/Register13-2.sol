// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


// En este ejemplo se muestra cómo utilizar un mapping avanzado en Solidity.:
// - Se define una estructura User que contiene un nombre y un balance.
// - Se utiliza un mapping users para asociar direcciones con estructuras User.
// - La función registerUser permite registrar un nuevo usuario.
// - La función updateBalance actualiza el balance del usuario llamante.
// - La función getUser permite obtener la información de un usuario registrado.

contract AdvancedMapping {
    // Define una estructura para almacenar información de los usuarios
    struct User {
        string name;
        uint256 balance;
        bool isClient;
    }

    // Define un mapping de direcciones a estructuras de usuarios
    mapping(address => User) public users;

    // Función para registrar un usuario
    function registerUser(string memory _name) public {
        require(!users[msg.sender].isClient, "Usuario ya registrado");
        users[msg.sender] = User(_name, 0, true);
    }

    // Función para actualizar el balance de un usuario
    function updateBalance(uint256 _amount) public {
        require(users[msg.sender].isClient, "Usuario no registrado");
        User storage user = users[msg.sender];
        user.balance += _amount;
        //users[msg.sender].balance += _amount; -> es lo mismo que las dos lineas anteriores
    }

    // Función para obtener la información de un usuario
    function getUser(address userAddress) public view returns (string memory, uint256, bool) {
        User memory user = users[userAddress];
        return (user.name, user.balance, user.isClient);
    }
}