// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title SimpleBank
 * @dev Smart contract para gestionar un banco sencillo donde los usuarios pueden registrarse, depositar y retirar ETH.
 */
contract SimpleBank {
    // Estructura que define un usuario
    struct User {
        string firstName;
        string lastName;
        uint256 balance;
        bool isRegistered;
    }

    // Mapping de direcciones a usuarios
    mapping(address => User) public users;

    // Dirección del propietario (owner)
    address public owner;

    // Dirección de la tesorería
    address public treasury;

    // Fee en puntos básicos (1% = 100 puntos básicos)
    uint256 public fee;

    // Balance acumulado en la tesorería
    uint256 public treasuryBalance;

    // Eventos
    event UserRegistered(address indexed user, string firstName, string lastName);
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount, uint256 feeAmount);
    event TreasuryWithdrawal(address indexed owner, uint256 amount);

    // Modificador para validar usuario registrado
    modifier onlyRegistered() {
        require(users[msg.sender].isRegistered, "Usuario no registrado");
        _;
    }

    // Modificador para validar propietario
    modifier onlyOwner() {
        require(msg.sender == owner, "Solo el owner puede ejecutar");
        _;
    }

    /**
     * @dev Constructor del contrato
     * @param _fee El fee en puntos básicos (1% = 100 puntos básicos)
     * @param _treasury La dirección de la tesorería
     */
    constructor(uint256 _fee, address _treasury) {
        require(_treasury != address(0), "Tesoreria invalida");
        require(_fee <= 10000, "Fee no puede exceder 10000 puntos");

        owner = msg.sender;
        fee = _fee;
        treasury = _treasury;
        treasuryBalance = 0;
    }

    /**
     * @dev Registra un nuevo usuario
     * @param _firstName El primer nombre del usuario
     * @param _lastName El apellido del usuario
     */
    function register(string calldata _firstName, string calldata _lastName) external {
        require(bytes(_firstName).length > 0, "Nombre no puede estar vacio");
        require(bytes(_lastName).length > 0, "Apellido no puede estar vacio");
        require(!users[msg.sender].isRegistered, "Usuario ya registrado");

        users[msg.sender] = User({
            firstName: _firstName,
            lastName: _lastName,
            balance: 0,
            isRegistered: true
        });

        emit UserRegistered(msg.sender, _firstName, _lastName);
    }

    /**
     * @dev Deposita ETH en la cuenta del usuario
     */
    function deposit() external payable onlyRegistered {
        require(msg.value > 0, "El deposito debe ser mayor a cero");

        users[msg.sender].balance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Verifica el saldo del usuario
     * @return El saldo del usuario en wei
     */
    function getBalance() external view onlyRegistered returns (uint256) {
        return users[msg.sender].balance;
    }

    /**
     * @dev Retira ETH de la cuenta del usuario, aplicando un fee
     * @param _amount La cantidad a retirar (en wei)
     */
    function withdraw(uint256 _amount) external onlyRegistered {
        require(_amount > 0, "Monto de retiro debe ser mayor a cero");
        require(users[msg.sender].balance >= _amount, "Saldo insuficiente");

        uint256 feeAmount = (_amount * fee) / 10000;
        uint256 netAmount = _amount - feeAmount;

        users[msg.sender].balance -= _amount;
        treasuryBalance += feeAmount;

        // Transferir al usuario
        payable(msg.sender).transfer(netAmount);
        emit Withdrawal(msg.sender, _amount, feeAmount);
    }

    /**
     * @dev Retira fondos de la cuenta de tesorería por el owner
     * @param _amount La cantidad a retirar de la tesorería (en wei)
     */
    function withdrawTreasury(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Monto debe ser mayor a cero");
        require(treasuryBalance >= _amount, "Balance de tesoreria insuficiente");

        treasuryBalance -= _amount;
        // Transferir al owner
        payable(owner).transfer(_amount);
        emit TreasuryWithdrawal(owner, _amount);
    }
}
