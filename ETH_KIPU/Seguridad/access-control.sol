// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title AccessControlDemo — Ejemplo de Control de Acceso (OpenZeppelin Contracts v5)
 * @notice Muestra cómo definir roles, asignarlos y restringir funciones según rol usando OZ v5
 */
contract AccessControlDemo is AccessControl {
    // === Definición de Roles ===
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant WRITER_ROLE = keccak256("WRITER_ROLE");

    // Estado protegido
    string private _document;

    /// @notice Al desplegar, el deployer recibe el rol de administrador y los roles definidos
    constructor(string memory initialDocument) {
        // OpenZeppelin v5: usar _grantRole en lugar de _setupRole
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(WRITER_ROLE, msg.sender);

        _document = initialDocument;
    }

    // === Funciones restringidas por rol ===

    /// @notice Pausa alguna lógica (simulado)
    /// @dev Solo cuenta con PAUSER_ROLE
    function pause() external onlyRole(PAUSER_ROLE) {
        // Lógica de pausa...
    }

    /// @notice Actualiza el documento
    /// @dev Solo WRITER_ROLE puede llamarla
    function setDocument(
        string calldata newDocument
    ) external onlyRole(WRITER_ROLE) {
        _document = newDocument;
    }

    /// @notice Lee el documento
    function getDocument() external view returns (string memory) {
        return _document;
    }

    // === Gestión de Roles ===

    /// @notice Otorga WRITER_ROLE a una cuenta
    function grantWriter(
        address account
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(WRITER_ROLE, account);
    }

    /// @notice Revoca WRITER_ROLE a una cuenta
    function revokeWriter(
        address account
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(WRITER_ROLE, account);
    }

    /// @notice Otorga PAUSER_ROLE a una cuenta
    function grantPauser(
        address account
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(PAUSER_ROLE, account);
    }

    /// @notice Revoca PAUSER_ROLE a una cuenta
    function revokePauser(
        address account
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(PAUSER_ROLE, account);
    }
}