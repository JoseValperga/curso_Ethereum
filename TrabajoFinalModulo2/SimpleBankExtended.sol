// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title SimpleBankExtended - Jose Valperga
 * @dev Smart contract para gestionar un banco sencillo donde los usuarios pueden registrarse, depositar y retirar ETH.
 */
contract SimpleBank {
    struct User {
        string firstName;
        string lastName;
        uint256 balance;
        bool isRegistered;
    }

    //Variables
    mapping(address => User) public users;
    address public owner;
    address public treasury;
    uint256 public fee;
    uint256 public treasuryBalance;

    //Eventos
    event UserRegistered(
        address indexed user,
        string firstName,
        string lastName
    );
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount, uint256 feeAmount);
    event TreasuryWithdrawal(address indexed owner, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    //Modificadores
    modifier onlyRegistered() {
        require(
            users[msg.sender].isRegistered,
            "El usuario no esta registrado"
        );
        _;
    }
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
        require(_treasury != address(0), "Direccion de tesoreria no valida");
        require(_fee <= 10000, "Fee debe ser <= 10000 puntos");

        owner = msg.sender;
        fee = _fee;
        treasury = _treasury;
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
        require(
            bytes(_firstName).length > 0,
            "Es obligatorio ingresar el primer nombre"
        );
        require(
            bytes(_lastName).length > 0,
            "Es obligatorio ingresar el apellido"
        );
        require(
            !users[msg.sender].isRegistered,
            "El usuario ya esta registrado"
        );

        users[msg.sender] = User({
            firstName: _firstName,
            lastName: _lastName,
            balance: 0,
            isRegistered: true
        });

        emit UserRegistered(msg.sender, _firstName, _lastName);
    }

    /**
     * @dev Función para hacer un depósito de ETH en la cuenta del usuario
     */
    function deposit() external payable onlyRegistered {
        require(msg.value > 0, "Debe ingresar una cantidad");

        users[msg.sender].balance += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Función para verificar el saldo del usuario
     * @return El saldo del usuario en wei
     */
    function getBalance() external view onlyRegistered returns (uint256) {
        return users[msg.sender].balance;
    }

    /**
     * @dev Función para retirar ETH de la cuenta del usuario
     * @param _amount La cantidad a retirar (en wei)
     */
    function withdraw(uint256 _amount) external onlyRegistered {
        require(_amount > 0, "Debe ingresar una cantidad");
        require(
            users[msg.sender].balance >= _amount,
            "Saldo insuficiente para la operacion solicitada"
        );

        uint256 feeAmount = (_amount * fee) / 10000;
        uint256 netAmount = _amount - feeAmount;

        users[msg.sender].balance -= _amount;
        treasuryBalance += feeAmount;
        payable(msg.sender).transfer(netAmount);

        emit Withdrawal(msg.sender, _amount, feeAmount);
    }

    /**
     * @dev Función para que el propietario retire fondos de la cuenta de tesorería
     * @param _amount La cantidad a retirar de la tesorería (en wei)
     */
    function withdrawTreasury(uint256 _amount) external onlyOwner {
        require(
            treasuryBalance >= _amount,
            "Saldo insuficiente en tesoreria para la operacion solicitada"
        );

        treasuryBalance -= _amount;
        payable(owner).transfer(_amount);

        emit TreasuryWithdrawal(msg.sender, _amount);
    }

     /**
     * @dev Función para registrar un nuevo usuario
     * @param _receiver Dirección del usuario destinoEl primer nombre del usuario
     * @param _amount Monto a transferir (en wei)
     */
    function transferBetweenUsers(address _receiver, uint256 _amount)
        external
        onlyRegistered
    {
        require(users[_receiver].isRegistered, "El usuario destino no esta registrado");
        require(_amount > 0, "Debe ingresar una cantidad");
        
        uint256 feeAmount = (_amount * fee) / 10000;
        uint netAmont = _amount+feeAmount;
        
        require(
            users[msg.sender].balance >= (netAmont),
            "Saldo insuficiente para la operacion solicitada"
        );
        users[msg.sender].balance -= (netAmont);
        users[_receiver].balance += _amount;
        treasuryBalance += feeAmount;

        emit Transfer(msg.sender, _receiver, _amount);

    }
}
