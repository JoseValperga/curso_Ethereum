// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//  NFT implementation

// ver implementación de interfaces en contrato ERC721.sol de OpenZeppelin
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol

/*
 1 - mapeo inverso
En el núcleo tenemos un mapeo de uint256 => dirección. 
Este es el reverso de un mapeo de token fungible (
por ejemplo, ERC-20) que es de address => uint256.
¿Por qué este mapeo inverso?
En los tokens fungibles, mapeamos desde el propietario hasta el saldo. 
Si bien en 721 también hacemos esto en un segundo mapeo 
(ver balanceOf a continuación), lo más importante es que necesitamos 
una forma de identificar tokens de forma única. 
Al mapear de uint256 a la dirección, podemos darle a cada token acuñado 
una identificación y asignar esta identificación a exactamente 
un propietario. Al crear un nuevo token NFT, crea un nuevo id 
(por lo general, solo comienza el id 1 y cuenta + 1 ) y establece el 
propietario como ownerMapping [id] = receiverAddress.
*/

// Mapping from token ID to owner address
mapping(uint256 => address) private _owners;

// Mapping owner address to token count
mapping(address => uint256) private _balances;

// 2 -Getters

// Devuelve el propietario del token NFT con la identificación proporcionada. 
// En la implementación 721, solo devolveríamos ownerMapping [id] aquí.
function ownerOf(uint256 tokenId) external view returns (address);

// Devuelve el saldo de un propietario, es decir, la cantidad total de 
// tokens NFT que posee esta dirección. En nuestra implementación, necesitaremos 
// realizar un seguimiento de esto al acuñar o transferir una NFT.
function balanceOf(address owner) external view returns (uint256);

/*
3 - Transferencias
La función de transferencia se presenta en tres formas. 
Este es probablemente la más utilizado. Transferirá el token con el id 
dada a la dirección de recepción. Solo funcionará si la dirección de 
remitente es del propietario o está aprobada (ver aprobaciones a continuación) 
y si el receptor no es un contrato  o un contrato  que implementa la interfaz
del receptor 721 (ver ERC-165 y cómo recibir tokens). De lo contrario, 
la llamada se revertirá.
Las otras dos variantes para las funciones de transferencia son simplemente 
una con un campo de datos de bytes adicionales para pasar al hook receptor 
y otra función de transferencia no segura que no invoca el hook de transferencia.
*/

function safeTransferFrom(address from, address to, uint256 tokenId) external payable;


/* 
4 - Aprovaciones
Las funciones de aprobación permiten que  apruebe otra dirección para
un token específico o para todos los tokens. 
Una vez que aprueba otra dirección, esta tiene control total sobre la transferencia.
*/

function approve(address approveTo, uint256 tokenId) external payable;
function getApproved(uint256 tokenId) external view returns (address);
function setApprovalForAll(address operator, bool isApproved) external;
function isApprovedForAll(address owner, address operator) external view returns (bool);


/* 
5 - Metadata (opcional)
Este tokenURI se vincula a un archivo de metadatos. En el caso de un juego,
el archivo podría estar alojado en los servidores del proveedor del juego.
En el espíritu de la descentralización, en muchos casos se utiliza IPFS para almacenar este archivo.
Solo asegúrese de usar IPFS pinning para no perder el archivo.
Podría verse así:
{
  "name": "Buzz",
  "description": "Paper collage, using salvaged and original watercolour papers", 
  "image": "https://ipfs.infura.io/ipfs/QmWc6YHE815F8kExchG9kd2uSsv7ZF1iQNn23bt5iKC6K3/image"
}
*/

interface ERC721Metadata {
    function name() external view returns (string name);
    function symbol() external view returns (string symbol);
    function tokenURI(uint256 tokenId) external view returns (string);
}

/*
6 - Enumeración (opcional)
Contiene funciones para contar y recibir tokens por índice.
*/

interface ERC721Enumerable {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}