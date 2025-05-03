// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title SimpleBank
 * @dev Smart contract para gestionar un banco sencillo donde los usuarios pueden registrarse, depositar y retirar ETH.
 */
contract SimpleBank {
    // TODO: Define la estructura User con los campos firstName, lastName, balance e isRegistered

    // TODO: Define el mapping para relacionar las direcciones con los usuarios

    // TODO: Declara la variable para almacenar la dirección del propietario del contrato

    // TODO: Declara la variable para almacenar la dirección de la tesorería

    // TODO: Define la variable para el fee en puntos básicos (1% = 100 puntos básicos)

    // TODO: Declara la variable para almacenar el balance acumulado en la tesorería

    // TODO: Define el evento UserRegistered que registre la dirección, el primer nombre y el apellido del usuario

    // TODO: Define el evento Deposit para registrar los depósitos de los usuarios con dirección y cantidad

    // TODO: Define el evento Withdrawal que registre el retiro de los usuarios, la cantidad y el fee

    // TODO: Define el evento TreasuryWithdrawal que registre el retiro de fondos de la tesorería por el propietario

    // TODO: Crea un modificador onlyRegistered para asegurar que el usuario esté registrado

    // TODO: Crea un modificador onlyOwner para asegurar que solo el propietario pueda ejecutar ciertas funciones

    /**
     * @dev Constructor del contrato
     * @param _fee El fee en puntos básicos (1% = 100 puntos básicos)
     * @param _treasury La dirección de la tesorería
     */
    constructor(uint256 _fee, address _treasury) {
        // TODO: Verificar que la dirección de tesorería no sea la dirección cero
        // TODO: Validar que el fee no sea mayor al 100% (10000 puntos básicos)

        // TODO: Asignar la dirección del desplegador como propietario del contrato
        // TODO: Inicializar el fee con el valor proporcionado
        // TODO: Inicializar la tesorería con la dirección proporcionada
        // TODO: Inicializar el balance de la tesorería a cero
    }

    /**
     * @dev Función para registrar un nuevo usuario
     * @param _firstName El primer nombre del usuario
     * @param _lastName El apellido del usuario
     */
    function register(string calldata _firstName, string calldata _lastName) external {
        // TODO: Validar que el primer nombre no esté vacío
        // TODO: Validar que el apellido no esté vacío
        // TODO: Verificar que el usuario no esté registrado previamente

        // TODO: Crear un nuevo usuario con balance cero y registrado como verdadero
        // TODO: Emitir el evento UserRegistered con la dirección del usuario y sus datos
    }

    /**
     * @dev Función para hacer un depósito de ETH en la cuenta del usuario
     */
    function deposit() external payable onlyRegistered {
        // TODO: Validar que la cantidad de Ether depositada sea mayor a cero

        // TODO: Agregar la cantidad depositada al balance del usuario

        // TODO: Emitir el evento Deposit con la dirección del usuario y la cantidad depositada
    }

    /**
     * @dev Función para verificar el saldo del usuario
     * @return El saldo del usuario en wei
     */
    function getBalance() external view onlyRegistered returns (uint256) {
        // TODO: Retornar el balance del usuario llamador
    }

    /**
     * @dev Función para retirar ETH de la cuenta del usuario
     * @param _amount La cantidad a retirar (en wei)
     */
    function withdraw(uint256 _amount) external onlyRegistered {
        // TODO: Validar que la cantidad a retirar sea mayor a cero
        // TODO: Verificar que el usuario tenga suficiente balance para cubrir el retiro

        // TODO: Calcular el fee en función del porcentaje definido
        // TODO: Calcular la cantidad después del fee

        // TODO: Restar el monto total (incluyendo el fee) del balance del usuario
        // TODO: Agregar el fee al balance de la tesorería

        // TODO: Transferir la cantidad después del fee al usuario llamador
        // TODO: Emitir el evento Withdrawal con la dirección del usuario, la cantidad y el fee
    }

    /**
     * @dev Función para que el propietario retire fondos de la cuenta de tesorería
     * @param _amount La cantidad a retirar de la tesorería (en wei)
     */
    function withdrawTreasury(uint256 _amount) external onlyOwner {
        // TODO: Verificar que haya suficiente balance en la tesorería para cubrir el retiro

        // TODO: Reducir el balance de la tesorería en la cantidad retirada

        // TODO: Transferir los fondos a la tesorería del propietario
        // TODO: Emitir el evento TreasuryWithdrawal con la dirección del propietario y la cantidad retirada
    }
}