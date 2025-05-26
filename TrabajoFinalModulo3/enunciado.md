# Interacción Práctica con Tokens ERC-20 y ERC-721

## Objetivo

Desarrollar un conjunto de contratos inteligentes que permitan interactuar con tokens **ERC-20** y **ERC-721** para realizar operaciones básicas como transferencias directas, autorizaciones y transferencias indirectas. Finalmente, integrar ambos estándares en un caso de uso práctico que combine el uso de ambas tecnologías.

---

## Plataforma de Subastas con Tokens

### 📌 Descripción

Implementar una plataforma de subastas donde los usuarios puedan pujar por NFTs utilizando tokens ERC-20.

### 🎯 Objetivos

- Crear contratos ERC-20 y ERC-721.
- Implementar un contrato de subasta donde:
  - Los usuarios depositen tokens ERC-20 para realizar sus ofertas.
  - Al finalizar la subasta, el NFT se transfiere al mejor postor y los tokens a los propietarios originales.

**Extras:** Añadir un cronómetro o lógica de tiempo para las subastas.

---

## 🚀 Flujo General

1. **Deployar los contratos:**
   - `AuctionToken`: con una cantidad inicial de tokens.
   - `AuctionNFT`: para crear y gestionar los NFTs.
   - `AuctionPlatform`: pasando las direcciones de los contratos anteriores.

2. **Crear una subasta:**
   - El propietario del NFT llama a `createAuction` en `AuctionPlatform`, especificando el `tokenId` y duración.

3. **Realizar pujas:**
   - Los usuarios llaman a `placeBid` transfiriendo tokens ERC-20 con la cantidad deseada.

4. **Finalizar la subasta:**
   - Una vez concluida, cualquier usuario puede llamar a `endAuction` para finalizarla.

---

## 🧠 Conceptos Clave

### 1. Transferencias de Tokens ERC-20

- `transfer`: Envía tokens desde el que llama a otro usuario.
- `approve`: Autoriza a otro usuario o contrato a gastar tokens en tu nombre.
- `transferFrom`: Permite transferir tokens desde otra cuenta si hay autorización previa.

### 2. Transferencias de Tokens ERC-721

- Similar a ERC-20 pero para tokens únicos.
- `transferFrom`: Transfiere un NFT si el llamante tiene autorización.

---

## 🔍 Explicación Detallada de `transferFrom`

### Para ERC-20:

1. Verifica saldo suficiente del `owner`.
2. Verifica `allowance` suficiente.
3. Disminuye el `allowance`.
4. Realiza la transferencia.

### Para ERC-721:

1. Verifica si `msg.sender` es propietario o autorizado.
2. Verifica existencia de `tokenId`.
3. Cambia la propiedad del NFT.

---

## ⚠️ Errores Comunes a Evitar

### ERC-20

- No llamar `approve` antes de `transferFrom`.
- Aprobar una cantidad insuficiente.
- No tener saldo suficiente.

### ERC-721

- Transferir sin ser propietario o sin autorización.
- No usar `approve` o `setApprovalForAll`.