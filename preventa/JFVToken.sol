// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title JFVToken
 * @notice ERC-20 utilitario con:
 * - Cap total (MAX_SUPPLY)
 * - Mint controlado por rol MINTER (crowdsale/vesting)
 * - Pausable controlado por rol PAUSER (operaciones)
 * - Burn opcional
 * - Permit (EIP-2612)
 * - AccessControl para roles + Ownable para ownership
 */
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract JFVToken is
    ERC20,
    ERC20Burnable,
    ERC20Pausable,
    ERC20Permit,
    AccessControl,
    Ownable
{
    /// @dev Roles de negocio
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Suministro máximo inmutable
    uint256 public immutable MAX_SUPPLY;

    /**
     * @param name_           Nombre (p.ej., "JFV Token")
     * @param symbol_         Símbolo (p.ej., "JFV")
     * @param maxSupply_      Cap total (18 decimales)
     * @param initialSupply_  Premint opcional al owner
     * @param initialOwner    Recibe ownership y DEFAULT_ADMIN_ROLE
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        uint256 initialSupply_,
        address initialOwner
    ) ERC20(name_, symbol_) ERC20Permit(name_) Ownable(initialOwner) {
        require(maxSupply_ > 0, "Invalid cap");
        require(initialOwner != address(0), "Zero owner");
        require(initialSupply_ <= maxSupply_, "Initial > cap");

        MAX_SUPPLY = maxSupply_;

        // Admin de roles (puede otorgar/revocar MINTER/PAUSER)
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);

        // Operaciones: el owner inicial también arranca con permiso de pausa
        _grantRole(PAUSER_ROLE, initialOwner);

        // Mint inicial (opcional)
        if (initialSupply_ > 0) {
            _mint(initialOwner, initialSupply_);
        }
    }

    /// @notice Mint controlado por rol MINTER (crowdsale/vesting)
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        require(totalSupply() + amount <= MAX_SUPPLY, "Cap exceeded");
        _mint(to, amount);
    }

    /// @notice Pausar/despausar transferencias (operaciones)
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @dev Hook necesario por ERC20Pausable
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }

    /// @dev Requisito de AccessControl
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
