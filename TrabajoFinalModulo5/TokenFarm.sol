// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "./DappToken.sol";
import "./LPToken.sol";

/**
 * @title Proportional Token Farm
 * @notice Una granja de staking donde las recompensas se distribuyen proporcionalmente al total stakeado.
 */
contract TokenFarm {
    //
    // Variables de estado
    //
    string public name = "Proportional Token Farm";
    address public owner;
    DAppToken public dappToken;
    LPToken public lpToken;
    address[] public stakersList;
    uint256 public rewardPerBlock;
    uint256 public feePercentage; // en basis points (10000 = 100%)
    uint256 public accumulatedFees;

    //uint256 public constant REWARD_PER_BLOCK = 1e18; // Recompensa por bloque (total para todos los usuarios)
    uint256 public totalStakingBalance; // Total de tokens en staking

    struct Staker {
        uint256 stakingBalance;
        uint256 checkpoint;
        uint256 pendingRewards;
        bool hasStaked;
        bool isStaking;
    }

    mapping(address => Staker) public stakers;

    // Eventos
    // Agregar eventos para Deposit, Withdraw, RewardsClaimed y RewardsDistributed.
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardsDistributed(uint256 totalRewards);

    //Modificadores
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    modifier isUserStaking() {
        require(stakers[msg.sender].isStaking, "You are not staking");
        _;
    }

    // Constructor
    constructor(DAppToken _dappToken, LPToken _lpToken) {
        // Configurar las instancias de los contratos de DappToken y LPToken.
        dappToken = _dappToken;
        lpToken = _lpToken;

        // Configurar al owner del contrato como el creador de este contrato.
        owner = msg.sender;

        rewardPerBlock = 1e18;
    }

    /**
     * @notice Configura el porcentaje de comisión para el contrato.
     * @param _newFee Nuevo porcentaje de comisión en basis points (10000 = 100%).
     * @dev El porcentaje máximo permitido es 1000 (10%).
     */
    function setFeePercentage(uint256 _newFee) external onlyOwner {
        require(_newFee <= 1000, "Fee too high"); // max 10%
        feePercentage = _newFee;
    }

    /**
     * @notice Retira las comisiones acumuladas en el contrato.
     * @param to Dirección a la que se enviarán las comisiones.
     * @dev Solo el owner puede retirar las comisiones acumuladas.
     */
    function withdrawAccumulatedFees(address to) external onlyOwner {
        uint256 amount = accumulatedFees;
        require(amount > 0, "No fees to withdraw");
        accumulatedFees = 0;
        dappToken.mint(to, amount);
    }

    /**
     * @notice Configura la recompensa por bloque.
     * @param _newReward Nueva recompensa por bloque.
     * @dev La recompensa debe ser positiva.
     */
    function setRewardPerBlock(uint256 _newReward) external onlyOwner {
        require(_newReward > 0, "Reward must be positive");
        rewardPerBlock = _newReward;
    }

    /**
     * @notice Deposita tokens LP para staking.
     * @param _amount Cantidad de tokens LP a depositar.
     */

    function deposit(uint256 _amount) external {
        // Verificar que _amount sea mayor a 0.
        require(_amount > 0, "Amount must be greater than 0");

        // Transferir tokens LP del usuario a este contrato.
        lpToken.transferFrom(msg.sender, address(this), _amount);

        // Actualizar el balance de staking del usuario en stakingBalance.
        Staker storage staker = stakers[msg.sender];
        staker.stakingBalance += _amount;

        // Incrementar totalStakingBalance con _amount.
        totalStakingBalance += _amount;

        // Si el usuario nunca ha hecho staking antes, agregarlo al array stakers y marcar hasStaked como true.
        if (!staker.hasStaked) {
            staker.hasStaked = true;
            stakersList.push(msg.sender); // Agregar al array de stakers.
        }

        // Actualizar isStaking del usuario a true.
        staker.isStaking = true;

        // Si checkpoints del usuario está vacío, inicializarlo con el número de bloque actual.
        if (staker.checkpoint == 0) {
            staker.checkpoint = block.number;
        } else {
            // Si ya tiene un checkpoint, llamar a distributeRewards para calcular recompensas pendientes.
            distributeRewards(msg.sender);
        }

        // Llamar a distributeRewards para calcular y actualizar las recompensas pendientes.
        //distributeRewards(msg.sender);

        // Emitir un evento de depósito.
        emit Deposit(msg.sender, _amount);
    }

    /**
     * @notice Retira todos los tokens LP en staking.
     */
    function withdraw() external isUserStaking {
        // Verificar que el usuario está haciendo staking (isStaking == true).
        Staker storage staker = stakers[msg.sender];
        //require(staker.isStaking, "You are not staking");

        // Obtener el balance de staking del usuario.
        uint256 balance = staker.stakingBalance;

        // Verificar que el balance de staking sea mayor a 0.
        require(balance > 0, "No staking balance available");

        // Llamar a distributeRewards para calcular y actualizar las recompensas pendientes antes de restablecer el balance.
        distributeRewards(msg.sender);

        // Restablecer stakingBalance del usuario a 0.
        staker.stakingBalance = 0;

        // Reducir totalStakingBalance en el balance que se está retirando.
        totalStakingBalance -= balance;

        // Actualizar isStaking del usuario a false.
        staker.isStaking = false;

        // Transferir los tokens LP de vuelta al usuario.
        lpToken.transfer(msg.sender, balance);

        // Emitir un evento de retiro.
        emit Withdraw(msg.sender, balance);
    }

    /**
     * @notice Reclama recompensas pendientes.
     */
    function claimRewards() external isUserStaking {
        // Asegurarse de que las recompensas estén actualizadas antes de reclamar.
        distributeRewards(msg.sender);

        // Obtener el monto de recompensas pendientes del usuario.
        Staker storage staker = stakers[msg.sender];
        uint256 pendingAmount = staker.pendingRewards;

        // Verificar que el monto de recompensas pendientes sea mayor a 0.
        require(pendingAmount > 0, "No pending rewards to claim");

        // Calcular comisión (fee)
        uint256 feeAmount = (pendingAmount * feePercentage) / 10000;
        uint256 userAmount = pendingAmount - feeAmount;

        // Acumular la comisión para el owner
        if (feeAmount > 0) {
            accumulatedFees += feeAmount;
        }

        // Restablecer las recompensas pendientes del usuario a 0.
        staker.pendingRewards = 0;

        // Mint solo la parte neta al usuario
        dappToken.mint(msg.sender, userAmount);

        // Emitir un evento de reclamo de recompensas.
        emit RewardsClaimed(msg.sender, pendingAmount);
    }

    /**
     * @notice Distribuye recompensas a todos los usuarios en staking.
     */
    function distributeRewardsAll() external onlyOwner {
        // Verificar que la llamada sea realizada por el owner.
        require(msg.sender == owner, "Only owner can distribute rewards");

        // Verificar que totalStakingBalance sea mayor a 0.
        require(totalStakingBalance > 0, "No staking balance available");

        // Iterar sobre todos los usuarios en staking almacenados en el array stakers.
        // Para cada usuario, si están haciendo staking (isStaking == true), llamar a distributeRewards.
        for (uint256 i = 0; i < stakersList.length; i++) {
            address beneficiary = stakersList[i];
            Staker storage staker = stakers[beneficiary];
            if (staker.isStaking && block.number > staker.checkpoint) {
                distributeRewards(beneficiary);
            }
        }

        // Emitir un evento indicando que las recompensas han sido distribuidas.
        emit RewardsDistributed(rewardPerBlock * totalStakingBalance);
    }

    /**
     * @notice Calcula y distribuye las recompensas proporcionalmente al staking total.
     * @dev La función toma en cuenta el porcentaje de tokens que cada usuario tiene en staking con respecto
     *      al total de tokens en staking (`totalStakingBalance`).
     *
     * Funcionamiento:
     * 1. Se calcula la cantidad de bloques transcurridos desde el último checkpoint del usuario.
     * 2. Se calcula la participación proporcional del usuario:
     *    share = stakingBalance[beneficiary] / totalStakingBalance
     * 3. Las recompensas para el usuario se determinan multiplicando su participación proporcional
     *    por las recompensas por bloque (`REWARD_PER_BLOCK`) y los bloques transcurridos:
     *    reward = REWARD_PER_BLOCK * blocksPassed * share
     * 4. Se acumulan las recompensas calculadas en `pendingRewards[beneficiary]`.
     * 5. Se actualiza el checkpoint del usuario al bloque actual.
     *
     * Ejemplo Práctico:
     * - Supongamos que:
     *    Usuario A ha stakeado 100 tokens.
     *    Usuario B ha stakeado 300 tokens.
     *    Total de staking (`totalStakingBalance`) = 400 tokens.
     *    `REWARD_PER_BLOCK` = 1e18 (1 token total por bloque).
     *    Han transcurrido 10 bloques desde el último checkpoint.
     *
     * Cálculo:
     * - Participación de Usuario A:
     *   shareA = 100 / 400 = 0.25 (25%)
     *   rewardA = 1e18 * 10 * 0.25 = 2.5e18 (2.5 tokens).
     *
     * - Participación de Usuario B:
     *   shareB = 300 / 400 = 0.75 (75%)
     *   rewardB = 1e18 * 10 * 0.75 = 7.5e18 (7.5 tokens).
     *
     * Resultado:
     * - Usuario A acumula 2.5e18 en `pendingRewards`.
     * - Usuario B acumula 7.5e18 en `pendingRewards`.
     *
     * Nota:
     * Este sistema asegura que las recompensas se distribuyan proporcionalmente y de manera justa
     * entre todos los usuarios en función de su contribución al staking total.
     */
    function distributeRewards(address beneficiary) private {
        // Obtener el último checkpoint del usuario desde checkpoints.
        Staker storage staker = stakers[beneficiary];
        uint256 currentBlock = block.number; //ahorro de gas

        // Verificar que el número de bloque actual sea mayor al checkpoint y que totalStakingBalance sea mayor a 0.
        require(
            currentBlock > staker.checkpoint,
            "No new blocks since last checkpoint"
        );
        require(totalStakingBalance > 0, "No staking balance available");

        // Calcular la cantidad de bloques transcurridos desde el último checkpoint.
        uint256 blocksPassed = currentBlock - staker.checkpoint;

        // Calcular la proporción del staking del usuario en relación al total staking (stakingBalance[beneficiary] / totalStakingBalance).
        uint256 share = (staker.stakingBalance * 1e18) / totalStakingBalance; // Usar 1e18 para mantener precisión.

        // Calcular las recompensas del usuario multiplicando la proporción por REWARD_PER_BLOCK y los bloques transcurridos.
        uint256 reward = (rewardPerBlock * blocksPassed * share) / 1e18; // Dividir por 1e18 para ajustar la precisión.

        // Actualizar las recompensas pendientes del usuario en pendingRewards.
        staker.pendingRewards += reward;

        // Actualizar el checkpoint del usuario al bloque actual.
        staker.checkpoint = block.number;
    }

    /**
     * @notice Calcula las recompensas pendientes del usuario hasta el bloque actual, sin modificar el estado.
     * @param beneficiary La dirección del usuario para consultar.
     * @return rewards Pendiente total de rewards considerando el tiempo pasado desde el último checkpoint.
     */
    function getPendingRewards(
        address beneficiary
    ) external view returns (uint256) {
        Staker storage staker = stakers[beneficiary];
        uint256 currentBlock = block.number;

        // Casos donde no puede haber nuevas recompensas
        if (
            staker.stakingBalance == 0 ||
            !staker.isStaking ||
            totalStakingBalance == 0 ||
            currentBlock <= staker.checkpoint
        ) {
            return staker.pendingRewards;
        }

        // Calcular bloques pasados desde el último checkpoint
        uint256 blocksPassed = currentBlock - staker.checkpoint;

        // Calcular participación proporcional
        uint256 share = (staker.stakingBalance * 1e18) / totalStakingBalance;

        // Calcular nuevas rewards acumuladas desde el checkpoint
        uint256 newRewards = (rewardPerBlock * blocksPassed * share) / 1e18;

        // Retornar rewards totales: las ya almacenadas + las recién calculadas
        return staker.pendingRewards + newRewards;
    }
}
