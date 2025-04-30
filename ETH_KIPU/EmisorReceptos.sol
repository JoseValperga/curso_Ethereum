// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ContratoEmisor {
    /// @notice Evento que se emite cuando se envía Ether exitosamente.
    event EtherEnviado(address indexed receptor, uint256 cantidad);

    /**
     * @notice Constructor del contrato.
     * @dev Aunque este contrato no requiere un constructor explícito, se menciona para mantener la estructura estándar.
     */
    constructor() {}

    /**
     * @notice Función `receive` para recibir Ether.
     * @dev Se activa automáticamente si el contrato recibe Ether sin datos de transacción.
     */
    receive() external payable {}

    /**
     * @notice Función `fallback` para recibir Ether.
     * @dev Se activa si el contrato recibe Ether con datos o si se llama a una función inexistente.
     */
    fallback() external payable {}

    /**
     * @notice Envía Ether a un contrato receptor.
     * @dev Utiliza el método call para transferir Ether y asegura que la transacción haya sido exitosa.
     * @param receptor La dirección del contrato receptor.
     */
    function enviarEther(address receptor) external payable {
        require(msg.value > 0, "Debes enviar alguna cantidad de Ether.");

        // Transferir Ether al contrato receptor.
        (bool exito, ) = receptor.call{value: msg.value}("");
        require(exito, "La transferencia de Ether ha fallado.");

        emit EtherEnviado(receptor, msg.value);
    }

    /**
     * @notice Esta función no es payable, por lo tanto, no puede recibir Ether.
     * @dev Llamar a esta función sin enviar Ether. De lo contrario, lanzará un error.
     */
    function notPayable() public {}
}

// ***********************************************************************************

pragma solidity ^0.8.18;

contract ContratoReceptor {
    /// @notice Almacena el balance de Ether recibido.
    uint256 public balanceRecibido;

    /// @notice Dirección del propietario que puede recibir Ether.
    address payable public owner;

    /// @notice Constructor payable que establece el propietario del contrato.
    /// @dev Este constructor se ejecuta una vez al desplegar el contrato y puede recibir Ether.
    constructor() payable {
        owner = payable(msg.sender);
    }

    /**
     * @notice Función `receive` para recibir Ether.
     * @dev Se ejecuta automáticamente cuando el contrato recibe Ether sin datos de transacción.
     */
    receive() external payable {
        balanceRecibido += msg.value;
    }

    /**
     * @notice Función `fallback` para recibir Ether.
     * @dev Se ejecuta cuando el contrato recibe Ether con datos de transacción o se llama a una función inexistente.
     */
    fallback() external payable {
        balanceRecibido += msg.value;
    }

    /**
     * @notice Retorna el balance de Ether almacenado en el contrato.
     * @return El balance en wei del contrato.
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Función para retirar todo el Ether del contrato.
     * @dev Solo el propietario del contrato puede realizar esta operación.
     */
    function withdraw() public {
        require(msg.sender == owner, "Solo el propietario puede retirar Ether");

        uint256 amount = address(this).balance;

        // Envía todo el Ether al propietario.
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Fallo en el envio de Ether");
    }
}
