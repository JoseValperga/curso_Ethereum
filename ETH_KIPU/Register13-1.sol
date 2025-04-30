// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Concepts: struct
/// @author Solange Gueiros
contract Register13 {
    //enum Colors {Undefined = 0, Blue = 1, Blue = 2}
    enum Colors {
        Undefined,
        Blue,
        Red
    }

    struct InfoStruct {
        string info;
        Colors color;
        uint256 countChanges;
    }

    InfoStruct storedInfo;

    constructor() {
        // Inicialización con valores por defecto
        storedInfo = InfoStruct({
            info: "Hello world",
            color: Colors.Undefined,
            countChanges: 0
        });

        // Inicialización en el orden de los campos de la estructura
        storedInfo = InfoStruct("Hello world", Colors.Undefined, 0);

        // Usando una variable temporal para realizar cálculos adicionales
        InfoStruct memory tempInfo = InfoStruct(
            "Hello world",
            Colors.Undefined,
            0
        );
        // Lógica adicional, si es necesario
        storedInfo = tempInfo;

        // campo por campo
        storedInfo.info = "Hello world";
        storedInfo.color = Colors.Undefined;
        storedInfo.countChanges = 0;
    }

    /**
     * Store `myColor` and `myInfo`
     * Increase the counter which how many times storedInfo is updated
     * @dev update the strict `storedInfo` with the parameters `myColor` and `myInfo`
     * @dev increase the counter
     * @param myColor the new color to store
     * @param myInfo the new string to store
     */
    function setInfo(Colors myColor, string memory myInfo) external {
        storedInfo.countChanges++;
        storedInfo.color = myColor;
        storedInfo.info = myInfo;
    }

    /**
     * Return the struct storedInfo
     * @dev return the struct storedInfo
     * @return the stored struct storedInfo
     */
    function getInfo() external view returns (InfoStruct memory) {
        return storedInfo;
    }
}
