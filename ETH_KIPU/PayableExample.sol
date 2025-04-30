// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title PayableExample
 * @dev Este contrato es una implementación educativa para explicar el uso de funciones `payable`
 * en Solidity. Permite que el contrato reciba y envíe Ether, incluyendo un monto inicial al desplegarse.
 */
contract PayableExample {
    /// @notice Evento que se emite cuando se recibe Ether en el contrato
    event Received(address sender, uint256 amount);

    /// @notice Evento que se emite cuando se envía Ether desde el contrato
    event Sent(address recipient, uint256 amount);

    /**
     * @notice Constructor que recibe Ether al desplegar el contrato
     * @dev Esta función se ejecuta solo una vez al momento de desplegar el contrato.
     * El modificador `payable` permite que el constructor reciba Ether durante el despliegue.
     */
    constructor() payable {
        require(msg.value > 0, "Debe enviar Ether al desplegar el contrato");

        // Emitimos un evento para registrar la recepción de Ether inicial
        emit Received(msg.sender, msg.value);
    }

    /**
     * @notice Permite recibir Ether directamente enviándolo al contrato.
     * @dev Esta función se ejecuta cuando se envía Ether sin especificar ninguna función.
     * `payable` permite que la función reciba Ether.
     */
    receive() external payable {
        // Emitimos un evento para registrar la recepción de Ether
        emit Received(msg.sender, msg.value);
    }

    /**
     * @notice Función fallback para manejar llamadas sin datos de Ether o con datos inválidos
     * @dev La función `fallback` es ejecutada cuando la llamada no coincide con ninguna función existente
     * en el contrato, o si se envía Ether sin especificar ninguna función y no hay datos.
     * La función es `payable`, ya que puede recibir Ether en este caso.
     */
    fallback() external payable {
        // Emitimos un evento para registrar la recepción de Ether o llamada incorrecta
        emit Received(msg.sender, msg.value);
    }

    /**
     * @notice Función para recibir Ether con un mensaje asociado
     * @dev Esta función permite a un remitente enviar Ether y almacenar un mensaje. Es `payable`
     * para que pueda aceptar Ether.
     * @param message Mensaje asociado con el envío de Ether
     */
    function depositWithMessage(string memory message) external payable {
        require(msg.value > 0, "Debe enviar algo de Ether");

        // Emitimos un evento para registrar la recepción de Ether
        emit Received(msg.sender, msg.value);

        // Podemos hacer uso del `message` si se necesita o guardarlo en el almacenamiento
        // Este ejemplo lo acepta sin almacenarlo, solo para fines educativos
    }

    /**
     * @notice Consulta el saldo de Ether almacenado en el contrato
     * @return uint256 El saldo en wei almacenado en este contrato
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Enviar Ether desde el contrato a una dirección específica
     * @dev Esta función envía Ether a una dirección indicada. Verifica que el contrato tenga suficiente balance.
     * @param recipient La dirección de la cuenta de destino
     * @param amount La cantidad de Ether a enviar (en wei)
     */
    function sendEther(address payable recipient, uint256 amount) public {
        require(
            amount <= address(this).balance,
            "Fondos insuficientes en el contrato"
        );

        // Transferencia de Ether al destinatario
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Error al enviar Ether");

        // Emitimos un evento para registrar el envío de Ether
        emit Sent(recipient, amount);
    }
}
