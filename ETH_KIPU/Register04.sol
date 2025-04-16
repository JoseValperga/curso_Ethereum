// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title Concepts: Type address, msg.sender, owner, if
/// @author Solange Gueiros
contract Register04 {
    string private storedInfo;
    //address public owner = 0xb6219CaB8C0C50474A43Df76572AbE9FC968d5aD;mi billetera
    address public owner;

    //owner->direccion del que paga->es la cuenta dueña del contrato
    //"owner" es una convencion, no es palabra reservada

    constructor() {
        owner = msg.sender; //msg tiene informacion del dueño de la transaccion
    }

    /**
     * Store `myInfo`
     * Check if the account sending the transaction is the contract owner.
     * In affirmative case, update `myInfo` and increase the counter.
     * Otherwise, nothing will happen.
     * @dev check if msg.sender is the owner, update `storedInfo` and increase the counter
     * @param myInfo the new string to store
     */
    function setInfo(string memory myInfo) external {
        if (msg.sender == owner) {
            storedInfo = myInfo;
        } else {
            storedInfo = "No autorizado";
        }
    }

    /**
     * Return the stored string
     * @dev retrieves the string of the state variable `storedInfo`
     * @return the stored string
     */
    function getInfo() external view returns (string memory) {
        return storedInfo;
    }
/*
    function changeOwner (address _newOwner) public {
         if (msg.sender == owner) {
            owner = _newOwner;
        }*/
}