// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title SimpleBank - Jose Valperga
 * @dev Smart contract para gestionar un banco sencillo donde los usuarios pueden registrarse, depositar y retirar ETH.
 */
contract SimpleBank {
    // TODO: Define la estructura User con los campos firstName, lastName, balance e isRegistered
    struct User {
        string firstName;
        string lastName;
        uint256 balance;
        bool isRegistered;
    }

    // TODO: Define el mapping para relacionar las direcciones con los usuarios
    mapping(address => User) public users;

    // TODO: Declara la variable para almacenar la dirección del propietario del contrato
    address public owner;

    // TODO: Declara la variable para almacenar la dirección de la tesorería
    address public treasury;

    // TODO: Define la variable para el fee en puntos básicos (1% = 100 puntos básicos)
    uint256 public fee;

    // TODO: Declara la variable para almacenar el balance acumulado en la tesorería
    uint256 public treasuryBalance;

    // TODO: Define el evento UserRegistered que registre la dirección, el primer nombre y el apellido del usuario
    event UserRegistered(
        address indexed user,
        string firstName,
        string lastName
    );

    // TODO: Define el evento Deposit para registrar los depósitos de los usuarios con dirección y cantidad
    event Deposit(address indexed user, uint256 amount);

    // TODO: Define el evento Withdrawal que registre el retiro de los usuarios, la cantidad y el fee
    event Withdrawal(address indexed user, uint256 amount, uint256 feeAmount);

    // TODO: Define el evento TreasuryWithdrawal para registrar los retiros de fondos de la tesorería por el propietario
    event TreasuryWithdrawal(address indexed owner, uint256 amount);

    // TODO: Crea un modificador onlyRegistered para asegurar que el usuario esté registrado
    modifier onlyRegistered() {
        require(
            users[msg.sender].isRegistered,
            "El usuario no esta registrado"
        );
        _;
    }

    // TODO: Crea un modificador onlyOwner para asegurar que solo el propietario pueda ejecutar ciertas funciones
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Solo el usuario puede llamar a esta funcion"
        );
        _;
    }

    /**
     * @dev Constructor del contrato
     * @param _fee El fee en puntos básicos (1% = 100 puntos básicos)
     * @param _treasury La dirección de la tesorería
     */
    constructor(uint256 _fee, address _treasury) {
        // TODO: Verificar que la dirección de tesorería no sea la dirección cero
        require(_treasury != address(0), "Direccion de tesoreria no valida");

        // TODO: Validar que el fee no sea mayor al 100% (10000 puntos básicos)
        require(_fee <= 10000, "Fee debe ser <= 10000 puntos");

        // TODO: Asignar la dirección del desplegador como propietario del contrato
        owner = msg.sender;

        // TODO: Inicializar el fee con el valor proporcionado
        fee = _fee;

        // TODO: Asignar la tesorería a la variable de salida con el valor proporcionado
        treasury = _treasury;

        // TODO: Inicializar el balance de la tesorería a cero
        treasuryBalance = 0;
    }

    /**
     * @dev Función para registrar un nuevo usuario
     * @param _firstName El primer nombre del usuario
     * @param _lastName El apellido del usuario
     */
    function register(string calldata _firstName, string calldata _lastName)
        external
    {
        // TODO: Validar que el primer nombre no esté vacío
        require(
            bytes(_firstName).length > 0,
            "Es obligatorio ingresar el primer nombre"
        );

        // TODO: Validar que el apellido no esté vacío
        require(
            bytes(_lastName).length > 0,
            "Es obligatorio ingresar el apellido"
        );

        // TODO: Verificar que el usuario no esté registrado previamente
        require(
            !users[msg.sender].isRegistered,
            "El usuario ya esta registrado"
        );

        // TODO: Crear un nuevo usuario con balance cero y registrado como verdadero
        users[msg.sender] = User({
            firstName: _firstName,
            lastName: _lastName,
            balance: 0,
            isRegistered: true
        });

        // TODO: Emitir el evento UserRegistered con la dirección del usuario y sus datos
        emit UserRegistered(msg.sender, _firstName, _lastName);
    }

    /**
     * @dev Función para hacer un depósito de ETH en la cuenta del usuario
     */
    function deposit() external payable onlyRegistered {
        // TODO: Validar que la cantidad de Ether depositada sea mayor a cero
        require(msg.value > 0, "Debe ingresar una cantidad");

        // TODO: Agregar la cantidad depositada al balance del usuario
        users[msg.sender].balance += msg.value;

        // TODO: Emitir el evento Deposit con la dirección del usuario y la cantidad depositada
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Función para verificar el saldo del usuario
     * @return El saldo del usuario en wei
     */
    function getBalance() external view onlyRegistered returns (uint256) {
        // TODO: Retornar el balance del usuario llamador
        return users[msg.sender].balance;
    }

    /**
     * @dev Función para retirar ETH de la cuenta del usuario
     * @param _amount La cantidad a retirar (en wei)
     */
    function withdraw(uint256 _amount) external onlyRegistered {
        // TODO: Validar que la cantidad a retirar sea mayor a cero
        require(_amount > 0, "Debe ingresar una cantidad");

        // TODO: Verificar que el usuario tenga suficiente balance para cubrir el retiro
        require(
            users[msg.sender].balance >= _amount,
            "Saldo insuficiente para la operacion solicitada"
        );

        // TODO: Calcular el fee en función del porcentaje definido
        uint256 feeAmount = (_amount * fee) / 10000;

        // TODO: Calcular la cantidad después del fee
        uint256 netAmount = _amount - feeAmount;

        // TODO: Restar el monto total (incluyendo el fee) del balance del usuario
        users[msg.sender].balance -= _amount;

        // TODO: Agregar el fee al balance de la tesorería
        treasuryBalance += feeAmount;

        // TODO: Transferir la cantidad después del fee al usuario llamador
        payable(msg.sender).transfer(netAmount);

        /*Se debe usar call en lugar de transfer 
        (bool success, bytes memory data) = msg.sender.call{ value: netAmount }("");
        require(success, "Envio fallido");
        */

        // TODO: Emitir el evento Withdrawal con la dirección del usuario, la cantidad y el fee
        emit Withdrawal(msg.sender, _amount, feeAmount);
    }

    /**
     * @dev Función para que el propietario retire fondos de la cuenta de tesorería
     * @param _amount La cantidad a retirar de la tesorería (en wei)
     */
    function withdrawTreasury(uint256 _amount) external onlyOwner {
        // TODO: Verificar que haya suficiente balance en la tesorería para cubrir el retiro
        require(
            treasuryBalance >= _amount,
            "Saldo insuficiente en tesoreria para la operacion solicitada"
        );

        // TODO: Reducir el balance de la tesorería en la cantidad retirada
        treasuryBalance -= _amount;

        // TODO: Transferir los fondos a la tesorería del propietario
        payable(owner).transfer(_amount);
        /*Se debe usar call en lugar de transfer 
        (bool success, bytes memory data) = owner.call{ value: netAmount }("");
        require(success, "Envio fallido");
        */

        // TODO: Emitir el evento treasuryWithdraw con la dirección del propietario y la cantidad retirada
        emit TreasuryWithdrawal(msg.sender, _amount);
    }
}
