// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title Registro con Acceso Controlado y Eventos
/// @author Tu Nombre
/// @notice Este contrato permite almacenar y actualizar una cadena de texto, con control de acceso y eventos.
contract RegistroConAcceso {

    // Estado de almacenamiento
    string private storedData;
    uint public numeroDeCambios;
    address public owner;

    // Evento que se emitirá cuando la información sea actualizada
    /// @notice Emite los valores antiguo y nuevo cuando se actualiza `storedData`
    /// @param antiguo Valor antes de la actualización
    /// @param nuevo Valor después de la actualización
    event DataActualizada(string antiguo, string nuevo);

    /**
     * @dev Constructor que asigna el rol de administrador al creador del contrato
     * y establece un valor inicial para `storedData`.
     * @param valorInicial El valor inicial para `storedData`.
     */
    constructor(string memory valorInicial) {
        owner = msg.sender;
        storedData = valorInicial;
        numeroDeCambios = 0;
    }

    /**
     * @dev Modificador que permite solo al administrador ejecutar ciertas funciones.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Solo el admin puede realizar esta accion");
        _;
    }

    /**
     * @notice Permite al administrador actualizar el dato almacenado.
     * @dev Emitir el evento `DataActualizada` cuando se modifique el valor de `storedData`.
     * @dev Incrementar el contador de cambios después de actualizar la información.
     * @param nuevoDato El nuevo dato que será almacenado.
     */
    function actualizarData(string memory nuevoDato) external onlyOwner {
        string memory antiguo = storedData;
        emit DataActualizada(antiguo, nuevoDato);
        storedData = nuevoDato;
        numeroDeCambios++;
    }

    /**
     * @notice Devuelve el dato almacenado actualmente.
     * @return El dato almacenado en la variable de estado `storedData`.
     */
    function obtenerData() external view returns (string memory) {
        return storedData;
    }

    /**
     * @notice Permite al administrador transferir su rol a otro usuario.
     * @param nuevoAdmin La dirección del nuevo administrador.
     * @dev Solo el administrador actual puede llamar a esta función.
     */
    function transferirAdmin(address nuevoAdmin) external onlyOwner {
        require(nuevoAdmin != address(0), "Direccion no valida");
        owner = nuevoAdmin;
    }
}
