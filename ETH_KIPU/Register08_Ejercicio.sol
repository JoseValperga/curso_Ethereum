// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Registro con Acceso Controlado y Eventos (Versión incompleta)
/// @author [Jose Valperga]
/// @notice Este contrato permite almacenar y actualizar una cadena de texto, con control de acceso y eventos.
contract RegistroConAcceso {
    // Estado de almacenamiento
    string private storedData;
    uint256 public numeroDeCambios = 0;
    address public owner;

    // Evento que se emitirá cuando la información sea actualizada
    event DataActualizada(string oldInfo, string newInfo);

    /**
     * @dev Constructor que asigna el rol de administrador al creador del contrato
     * y establece un valor inicial para `storedData`.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Modificador que permite solo al administrador ejecutar ciertas funciones.
     * TODO: Completar este modificador para que solo el `admin` pueda ejecutar las funciones restringidas.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    /**
     * @notice Permite al administrador actualizar el dato almacenado.
     * @dev Emitir el evento `DataActualizada` cuando se modifique el valor de `storedData`.
     * @dev Incrementar el contador de cambios después de actualizar la información.
     * @param nuevoDato El nuevo dato que será almacenado.
     * TODO: Implementar la funcionalidad de esta función.
     */
    function actualizarData(string memory nuevoDato) external onlyOwner {
        // TODO: Emitir el evento DataActualizada con el valor antiguo y nuevo
        string memory antiguo = storedData;
        emit DataActualizada(antiguo, nuevoDato);
        // TODO: Actualizar el valor de `storedData` con `nuevoDato`
        storedData = nuevoDato;
        // TODO: Incrementar el contador `numeroDeCambios`
        numeroDeCambios++;
    }

    /**
     * @notice Devuelve el dato almacenado actualmente.
     * @return El dato almacenado en la variable de estado `storedData`.
     * TODO: Implementar esta función para devolver el dato almacenado.
     */
    function obtenerData() external view returns (string memory) {
        // Completar el retorno de `storedData`
        return storedData;
    }

    /**
     * @notice Permite al administrador transferir su rol a otro usuario.
     * @param nuevoAdmin La dirección del nuevo administrador.
     * @dev Solo el administrador actual puede llamar a esta función.
     * TODO: Completar la función para permitir la transferencia de la propiedad.
     */
    function transferirAdmin(address nuevoAdmin) external onlyOwner {
        // TODO: Asignar la dirección `nuevoAdmin` como el nuevo `admin`
        require(nuevoAdmin != address(0), "Direccion no valida");
        owner = nuevoAdmin;
    }
}
