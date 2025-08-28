// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title JFVCrowdsale
 * @notice Venta de JFV a cambio de ETH con ventana de tiempo, soft/hard cap,
 *         límites por wallet, TGE y refunds. Minteo diferido por claims.
 *
 * Modelo: "claim-based"
 * - buyTokens: registra aportes y asigna tokens (NO mintea aún)
 * - finalize: decide éxito/fracaso cuando cierra la venta
 * - claimTGE: mintea % TGE a cada comprador si la venta fue exitosa
 * - claimRefund: devuelve ETH si no se alcanzó el soft cap
 *
 * NOTA: El vesting del 80% restante se recomienda en un contrato externo;
 *       este MVP no incluye vesting embebido para mantener el tamaño y la claridad.
 */

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import {IJFVToken} from "../scripts/interfaces/IJFVToken.sol"; // interfaz mínima del mint;

contract JFVCrowdsale is ReentrancyGuard, Pausable, AccessControl {
    // ========= Roles =========
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant CONFIG_ROLE = keccak256("CONFIG_ROLE"); // usar sólo en testnet/preventa

    // ========= Eventos =========
    event TokensPurchased(
        address indexed buyer,
        address indexed beneficiary,
        uint256 valueETH,
        uint256 amountJFV
    );
    event Finalized(bool success);
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 valueETH);
    event TGEClaimed(address indexed beneficiary, uint256 amountJFV);
    event LimitsUpdated(uint256 minContribution, uint256 maxContribution);
    event TimesUpdated(uint64 openingTime, uint64 closingTime);
    event RateUpdated(uint256 oldRate, uint256 newRate);
    event WalletUpdated(address oldWallet, address newWallet);

    // ========= Errores =========
    error SaleNotOpen();
    error SaleNotClosed();
    error AlreadyFinalized();
    error SoftCapNotReached();
    error RefundsNotEnabled();
    error CapExceeded();
    error MinMaxViolation();
    error NothingToClaim();
    error ZeroAddress();
    error InvalidParams();

    // ========= Inmutables / configuración principal =========
    IJFVToken public immutable token; // JFVToken con MINTER_ROLE otorgado a este contrato
    address public wallet; // Tesorería receptora del ETH si hay éxito
    uint256 public rate; // JFV por 1 ETH

    uint256 public immutable softCap; // ETH mínimo para éxito
    uint256 public immutable hardCap; // ETH máximo aceptado
    uint64 public openingTime; // inicio
    uint64 public closingTime; // fin

    uint256 public minContribution; // por wallet (suma total)
    uint256 public maxContribution; // por wallet (suma total)

    uint16 public immutable tgeBps; // % TGE en basis points (ej. 2000 = 20%)

    // ========= Estado de la venta =========
    uint256 public weiRaised;
    uint256 public tokensSold;

    mapping(address => uint256) public contributed; // ETH total por comprador
    mapping(address => uint256) public allocated; // JFV asignados por comprador
    mapping(address => uint256) public tgeClaimed; // JFV TGE reclamados

    bool public finalized;
    bool public refunding;

    constructor(
        address token_,
        address wallet_,
        uint256 rate_,
        uint256 softCap_,
        uint256 hardCap_,
        uint64 openingTime_,
        uint64 closingTime_,
        uint256 minContribution_,
        uint256 maxContribution_,
        uint16 tgeBps_,
        address admin_ // DEFAULT_ADMIN_ROLE holder (ej. mi address / multisig)
    ) {
        if (
            token_ == address(0) ||
            wallet_ == address(0) ||
            admin_ == address(0) ||
            rate_ == 0 ||
            softCap_ == 0 ||
            hardCap_ == 0 ||
            hardCap_ <= softCap_ ||
            openingTime_ >= closingTime_ ||
            minContribution_ == 0 ||
            maxContribution_ == 0 ||
            maxContribution_ < minContribution_ ||
            tgeBps_ > 10_000
        ) revert InvalidParams();

        token = IJFVToken(token_);
        wallet = wallet_;

        rate = rate_;
        softCap = softCap_;
        hardCap = hardCap_;
        openingTime = openingTime_;
        closingTime = closingTime_;
        minContribution = minContribution_;
        maxContribution = maxContribution_;
        tgeBps = tgeBps_;

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(PAUSER_ROLE, admin_);
        _grantRole(CONFIG_ROLE, admin_); // útil en testnet; puedes revocarlo en mainnet
    }

    // ========= Lecturas de estado =========
    function isOpen() public view returns (bool) {
        return
            block.timestamp >= openingTime &&
            block.timestamp <= closingTime &&
            weiRaised < hardCap &&
            !paused();
    }

    function isClosed() public view returns (bool) {
        return block.timestamp > closingTime || weiRaised >= hardCap;
    }

    // ========= Compra =========
    function buyTokens(
        address beneficiary
    ) external payable nonReentrant whenNotPaused {
        if (!isOpen()) revert SaleNotOpen();
        if (beneficiary == address(0)) revert ZeroAddress();
        if (msg.value == 0) revert MinMaxViolation();
        if (weiRaised + msg.value > hardCap) revert CapExceeded();

        uint256 newContribution = contributed[msg.sender] + msg.value;
        if (
            newContribution < minContribution ||
            newContribution > maxContribution
        ) {
            revert MinMaxViolation();
        }

        // calcular tokens asignados
        // amountJFV = msg.value * rate (assume 18/18)
        uint256 amountJFV = msg.value * rate;

        weiRaised += msg.value;
        tokensSold += amountJFV;
        contributed[msg.sender] = newContribution;
        allocated[beneficiary] += amountJFV;

        emit TokensPurchased(msg.sender, beneficiary, msg.value, amountJFV);
    }

    // ========= Finalización =========
    function finalize() external nonReentrant {
        if (!isClosed()) revert SaleNotClosed();
        if (finalized) revert AlreadyFinalized();

        finalized = true;

        if (weiRaised >= softCap) {
            emit Finalized(true);
            // éxito: no transferimos ETH aún; tesorería hará withdrawETH()
        } else {
            refunding = true;
            emit RefundsEnabled();
            emit Finalized(false);
        }
    }

    // ========= Claims =========
    function claimTGE() external nonReentrant whenNotPaused {
        if (!finalized || refunding) revert SoftCapNotReached();

        uint256 alloc = allocated[msg.sender];
        if (alloc == 0) revert NothingToClaim();

        uint256 tgeTotal = (alloc * tgeBps) / 10_000;
        uint256 already = tgeClaimed[msg.sender];
        if (tgeTotal <= already) revert NothingToClaim();

        uint256 due = tgeTotal - already;
        tgeClaimed[msg.sender] = tgeTotal; // marcar todo el TGE como reclamado (idempotente)

        // mintear desde el token hacia el usuario (este contrato debe tener MINTER_ROLE)
        token.mint(msg.sender, due);

        emit TGEClaimed(msg.sender, due);
    }

    // ========= Refunds (si falla soft cap) =========
    function claimRefund() external nonReentrant {
        if (!refunding) revert RefundsNotEnabled();

        uint256 amount = contributed[msg.sender];
        if (amount == 0) revert NothingToClaim();

        contributed[msg.sender] = 0;
        // Interacción al final (pull payment)
        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "Refund transfer failed");

        emit Refunded(msg.sender, amount);
    }

    // ========= Retiro de ETH (tesorería) =========
    function withdrawETH() external nonReentrant {
        if (!finalized || refunding) revert SoftCapNotReached();
        uint256 bal = address(this).balance;
        (bool ok, ) = payable(wallet).call{value: bal}("");
        require(ok, "Withdraw failed");
    }

    // ========= Admin / Operación =========
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // Los siguientes setters son útiles para testnet y **solo antes de abrir**
    function setLimits(
        uint256 newMin,
        uint256 newMax
    ) external onlyRole(CONFIG_ROLE) {
        if (block.timestamp >= openingTime) revert SaleNotOpen();
        if (newMin == 0 || newMax == 0 || newMax < newMin)
            revert InvalidParams();
        minContribution = newMin;
        maxContribution = newMax;
        emit LimitsUpdated(newMin, newMax);
    }

    function setTimes(
        uint64 newOpen,
        uint64 newClose
    ) external onlyRole(CONFIG_ROLE) {
        if (block.timestamp >= openingTime) revert SaleNotOpen();
        if (newOpen >= newClose) revert InvalidParams();
        openingTime = newOpen;
        closingTime = newClose;
        emit TimesUpdated(newOpen, newClose);
    }

    function setRate(uint256 newRate) external onlyRole(CONFIG_ROLE) {
        if (block.timestamp >= openingTime) revert SaleNotOpen();
        if (newRate == 0) revert InvalidParams();
        uint256 old = rate;
        rate = newRate;
        emit RateUpdated(old, newRate);
    }

    function setWallet(address newWallet) external onlyRole(CONFIG_ROLE) {
        if (block.timestamp >= openingTime) revert SaleNotOpen();
        if (newWallet == address(0)) revert ZeroAddress();
        address old = wallet;
        wallet = newWallet;
        emit WalletUpdated(old, newWallet);
    }

    // Fallback / receive para ETH directo (opcional: redirigir a buyTokens si querés)
    receive() external payable {
        // Mantener fondos aquí; compras deben llamarse con buyTokens
        // para registrar beneficiary explícito.
    }
}

interface IJFVToken {
    function mint(address to, uint256 amount) external;
}

