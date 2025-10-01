// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;
import "./IJFVToken.sol";
import "./JFVToken.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@Openzeppelin/contracts/utils/Address.sol";

contract JFVCrowdsale is ReentrancyGuard, Pausable, AccessControl {
    using Address for address payable;
    // Roles
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant CONFIG_ROLE = keccak256("CONFIG_ROLE");

    // ========= Config principal =========
    IJFVToken public immutable token; // JFVToken con MINTER_ROLE otorgado a este contrato
    address public wallet; // Tesorería
    uint256 public rate; // JFV por 1 ETH (rate con 18 decimales)

    uint256 public immutable softCap; // ETH mínimo para éxito
    uint256 public immutable hardCap; // ETH máximo aceptado
    uint256 public openingTime; // inicio
    uint256 public closingTime; // fin

    uint256 public minContribution; // por wallet (suma total)
    uint256 public maxContribution; // por wallet (suma total)

    uint256 public immutable tgeBps; // % TGE en basis points (ej. 2000 = 20%)

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
    // cambios de config (para pruebas)
    event LimitsUpdated(uint256 minContribution, uint256 maxContribution);
    event TimesUpdated(uint64 openingTime, uint64 closingTime);
    event RateUpdated(uint256 oldRate, uint256 newRate);
    event WalletUpdated(address oldWallet, address newWallet);

    // ========= Estado =========
    uint256 public weiRaised;
    uint256 public tokensSold;

    mapping(address => uint256) public contributed; // ETH total por comprador
    mapping(address => uint256) public allocated; // JFV asignados por comprador
    mapping(address => uint256) public tgeClaimed; // JFV TGE reclamados

    bool public finalized;
    bool public refunding;

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
    error MintFailed();

    constructor(
        address _token,
        address _wallet,
        uint256 _rate, // tokens por 1 ETH (con 18 decimales)
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _minContribution,
        uint256 _maxContribution,
        uint256 _tgeBps,
        address _admin
    ) {
        require(_token != address(0), "Token address is zero");
        require(_wallet != address(0), "Wallet address is zero");
        require(_rate > 0, "Rate is zero");
        require(_softCap > 0, "Soft cap is zero");
        require(_hardCap > 0, "Hard cap is zero");
        require(_softCap <= _hardCap, "Soft cap exceeds hard cap");
        require(_openingTime >= block.timestamp, "Opening before now");
        require(_closingTime > _openingTime, "Closing before opening");
        require(_minContribution > 0, "Min contribution is zero");
        require(_maxContribution > 0, "Max contribution is zero");
        require(_minContribution <= _maxContribution, "Min > Max");
        require(_tgeBps <= 10_000, "TGE bps > 10000");
        require(_admin != address(0), "Admin address is zero");

        token = IJFVToken(_token);
        wallet = _wallet;
        rate = _rate;
        softCap = _softCap;
        hardCap = _hardCap;
        openingTime = _openingTime;
        closingTime = _closingTime;
        minContribution = _minContribution;
        maxContribution = _maxContribution;
        tgeBps = _tgeBps;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(PAUSER_ROLE, _admin);
        _grantRole(CONFIG_ROLE, _admin);
    }

    // --- control operativo ---
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // --- bloquear ETH directo ---
    receive() external payable {
        revert("Use buyTokens()");
    }

    fallback() external payable {
        revert("Invalid call");
    }

    function isOpen() public view returns (bool) {
        return (block.timestamp >= openingTime &&
            block.timestamp <= closingTime &&
            weiRaised < hardCap &&
            !finalized);
    }

    function isClosed() public view returns (bool) {
        return (block.timestamp > closingTime ||
            weiRaised >= hardCap ||
            finalized);
    }

    function buyTokens(
        address beneficiary
    ) external payable nonReentrant whenNotPaused {
        require(beneficiary == msg.sender, "Only self-buy");
        
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

        // Calcular tokens: rate = tokens por 1 ETH (18 decimales)
        uint256 amountJFV = (msg.value * rate) / 1e18;

        weiRaised += msg.value;
        tokensSold += amountJFV;
        contributed[msg.sender] = newContribution;
        allocated[beneficiary] += amountJFV;

        emit TokensPurchased(msg.sender, beneficiary, msg.value, amountJFV);
    }

    function finalize() external {
        if (!isClosed()) revert SaleNotClosed();
        if (finalized) revert AlreadyFinalized();
        finalized = true;
        if (weiRaised >= softCap) {
            emit Finalized(true);
        } else {
            refunding = true;
            emit RefundsEnabled();
            emit Finalized(false);
        }
    }

    function claimTGE() external nonReentrant whenNotPaused {
        if (!finalized || refunding) revert SoftCapNotReached();

        uint256 alloc = allocated[msg.sender];
        if (alloc == 0) revert NothingToClaim();

        uint256 tgeTotal = (alloc * tgeBps) / 10_000;

        uint256 already = tgeClaimed[msg.sender];
        if (tgeTotal <= already) revert NothingToClaim();

        uint256 due = tgeTotal - already;
        tgeClaimed[msg.sender] = tgeTotal;

        try token.mint(msg.sender, due) {
            // ok
        } catch {
            revert MintFailed();
        }

        emit TGEClaimed(msg.sender, due);
    }

    function claimRefunds() external nonReentrant whenNotPaused {
        if (!refunding) revert RefundsNotEnabled();
        uint256 amount = contributed[msg.sender];
        if (amount == 0) revert NothingToClaim();

        contributed[msg.sender] = 0;
        /*
        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "Refund transfer failed");
        emit Refunded(msg.sender, amount);
        */
         payable(msg.sender).sendValue(amount);

        emit Refunded(msg.sender, amount);
    }

    // ========= Retiro de ETH (tesorería) =========
    function withdrawETH() external nonReentrant onlyRole(CONFIG_ROLE) {
        if (!finalized || refunding) revert SoftCapNotReached();
        uint256 bal = address(this).balance;
        /*
        (bool ok, ) = payable(wallet).call{value: bal}("");
        require(ok, "Withdraw failed");
        */
        payable(wallet).sendValue(bal);
    }

    // ========= Helpers de lectura (opcional para front) =========
    function tgeClaimableOf(address user) external view returns (uint256) {
        if (!finalized || refunding) return 0;
        uint256 alloc = allocated[user];
        if (alloc == 0) return 0;
        uint256 tgeTotal = (alloc * tgeBps) / 10_000;
        uint256 already = tgeClaimed[user];
        if (tgeTotal <= already) return 0;
        return tgeTotal - already;
    }

    // ========= Setters de prueba (proteger con CONFIG_ROLE) =========
    function setRate(uint256 newRate) external onlyRole(CONFIG_ROLE) {
        emit RateUpdated(rate, newRate);
        rate = newRate;
    }

    function setTimes(
        uint64 start_,
        uint64 end_
    ) external onlyRole(CONFIG_ROLE) {
        require(start_ < end_, "time");
        emit TimesUpdated(start_, end_);
        openingTime = start_;
        closingTime = end_;
    }

    function setLimits(
        uint256 min_,
        uint256 max_
    ) external onlyRole(CONFIG_ROLE) {
        require(min_ > 0 && max_ > 0 && min_ <= max_, "limits");
        emit LimitsUpdated(min_, max_);
        minContribution = min_;
        maxContribution = max_;
    }

    function setWallet(address newWallet) external onlyRole(CONFIG_ROLE) {
        if (newWallet == address(0)) revert ZeroAddress();
        emit WalletUpdated(wallet, newWallet);
        wallet = newWallet;
    }
}
