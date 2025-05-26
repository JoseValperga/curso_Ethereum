```markdown
# Guía de Uso de los Contratos de Subasta

A continuación encontrarás una guía visual y organizada para interactuar con los tres contratos principales de tu plataforma: `AuctionToken`, `AuctionNFT` y `AuctionPlatform`.

---

## 📦 Uso de AuctionToken

**Funciones disponibles:**

| Método          | ¿Para qué sirve?                                                                                                    |
|-----------------|----------------------------------------------------------------------------------------------------------------------|
| **approve**     | Autoriza a otra dirección a gastar un número determinado de tus tokens (paso previo a `transferFrom`).              |
| **mint**        | Crea nuevos tokens y los asigna a una dirección. Solo el propietario puede ejecutar esta función.                    |
| **pause**       | Detiene temporalmente todas las transferencias (medida de seguridad).                                                |
| **unpause**     | Reactiva las transferencias detenidas con `pause`.                                                                  |
| **permit**      | Implementa EIP‑2612: aprueba gastos delegados mediante firma off‑chain (sin gas para el titular).                    |
| **renounceOwner** | Elimina al propietario del contrato, bloqueando funciones `onlyOwner`.                                            |
| **transfer**    | Envía tus propios tokens a otra dirección (transferencia directa).                                                    |
| **transferFrom**| Gasta tokens de otra cuenta autorizada (usa con `approve` o `permit`).                                              |
| **transferOwner** | Transfiere la propiedad del contrato a otra dirección.                                                           |

> **Venta de ATKN:**
>
> El contrato `AuctionToken` **no incluye** lógica de venta. Para intercambiar ATKN por ETH o cualquier otro activo necesitas un **mercado externo** o un **contrato de subasta** que:
> 1. Reciba el pago (por ejemplo, Ether).
> 2. Llame a `mint` o `transfer` para entregar ATKN al comprador.

### 🛠  Cómo acuñar ATKN a un tercero (Remix)

1. **Compila y despliega**  
   - En **Solidity Compiler**, compila `AuctionToken`.  
   - En **Deploy & Run Transactions**, despliega el contrato como propietario.
2. **Localiza `mint`**  
   - Bajo **Deployed Contracts**, expande tu instancia.  
   - Rellena:
     - **to:** Dirección del tercero.  
     - **amount:** Cantidad en wei (ej. para 1 000 ATKN con 18 decimales: `1000000000000000000000000`).  
   - Haz clic en **transact**.
3. **Verifica**  
   - Ejecuta `balanceOf(tercero)` para comprobar el saldo.  
   - Ejecuta `totalSupply()` para revisar el suministro total.

---

## 🎨 Uso de AuctionNFT

**Funciones disponibles:**

| Método                     | ¿Para qué sirve?                                                                                                 |
|----------------------------|-------------------------------------------------------------------------------------------------------------------|
| **approve**                | Autoriza a otra dirección a transferir un token específico (tokenId).                                              |
| **safeMint**               | Crea un NFT y lo asigna; garantiza compatibilidad con contratos receptores.                                       |
| **pause**                  | Detiene todas las transferencias y acuñaciones (emergencia).                                                      |
| **unpause**                | Reactiva las funciones bloqueadas por `pause`.                                                                   |
| **renounceOwner**          | Elimina al propietario, bloqueando funciones `onlyOwner`.                                                        |
| **transferOwner**          | Transfiere la administración a otra dirección.                                                                   |
| **safeTransferFrom(3 par.)**| Transfiere un NFT de forma segura, asegurando que el receptor implemente ERC‑721.                               |
| **safeTransferFrom(4 par.)**| Igual, pero con datos adicionales al receptor.                                                                  |
| **transferFrom**           | Transfiere un NFT sin comprobación de receptor; usar con precaución.                                             |
| **setApprovalForAll**      | Autoriza o revoca un operador para gestionar *todos* tus NFTs.                                                   |

> **Venta de ANFT:**
>
> `AuctionNFT` **no incorpora** lógica de venta. Para subastar o vender necesitas un **marketplace** o **contrato de subasta** que:
> 1. Reciba el pago en ETH (u otro token).  
> 2. Transfiera el NFT al comprador (usando `safeTransferFrom` o `safeMint`).

### 🛠  Cómo acuñar y preparar tu NFT (Remix)

1. **Compila y despliega**  
   - En **Solidity Compiler**, compila `AuctionNFT`.  
   - Despliega indicando tu cuenta como propietario.
2. **Llamar a `safeMint`**  
   - Bajo **Deployed Contracts**, expande tu contrato.  
   - Rellena la dirección de destino (por ejemplo, `0xTercero…`) y haz clic en **transact**.
3. **Verifica**  
   - Ejecuta `ownerOf(tokenId)` para confirmar que el NFT llegó.
4. **Autorizar a la subasta**  
   - Como dueño del NFT, llama a:
     - `setApprovalForAll(AuctionPlatform, true)`  
     - o `approve(AuctionPlatform, tokenId)`.

---

## 🏛️ Uso de AuctionPlatform

### 1. Preparación

- **Despliega**:
  1. `AuctionToken` (ATKN)
  2. `AuctionNFT` (ANFT)
  3. `AuctionPlatform`, pasando las direcciones de los dos contratos anteriores.

### 2. Crear una subasta

1. **Selecciona la cuenta vendedora** (dueña del NFT).  
2. **Autoriza** el NFT con `setApprovalForAll(AuctionPlatform, true)`.  
3. Llama a `createAuction(tokenId, duration_in_seconds)`.  
4. Verifica con `auctions(auctionId)`:
   - `seller` correcto  
   - `tokenId` y `endTime` adecuados  
   - `active == true`

### 3. Realizar pujas

1. **Selecciona la cuenta pujadora**.  
2. **Autoriza** ATKN con `approve(AuctionPlatform, amount)`.  
3. Llama a `placeBid(auctionId, bidAmount)`.  
4. Verifica con `auctions(auctionId)`:
   - `highestBidder` y `highestBid` actualizados.

### 4. Finalizar la subasta

1. Espera a que `block.timestamp >= endTime`.  
2. Llama a `endAuction(auctionId)`.  
3. **Resultados esperados**:
   - El **NFT** pasa al `highestBidder`.  
   - Los **ATKN** pasan al `seller`.  
   - `active` queda en `false`.

---

> ¡Listo! Con esta guía organizada, podrás interactuar fácilmente con tus contratos desde Remix, sin escribir ni una sola línea extra de Solidity. 🚀
```








