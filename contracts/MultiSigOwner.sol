// SPDX-License-Identifier: LICENSED
pragma solidity ^0.7.0;
pragma abicoder v2;

contract MultiSigOwner {
    address[] public owners;
    mapping(uint256 => bool) public signatureId;
    bool private initialized;
    // events
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    modifier validSignOfOwner(
        bytes calldata signData,
        bytes calldata keys,
        string memory functionName
    ) {
        address signer = getSigner(signData, keys);
        require(signer != msg.sender && isOwner(signer), "is");
        (bytes4 method, uint256 id, ) = abi.decode(
            signData,
            (bytes4, uint256, bytes)
        );
        require(
            signatureId[id] == false &&
                method == bytes4(keccak256(bytes(functionName))),
            "sru"
        );
        signatureId[id] = true;
        _;
    }
    /// modifier functions
    modifier onlyOwner() {
        require(isOwner(msg.sender), "on");
        _;
    }

    function isOwner(address addr) public view returns (bool) {
        bool _isOwner = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                _isOwner = true;
            }
        }
        return _isOwner;
    }

    constructor() {}

    function initializeOwners(address[3] memory _owners) public {
        require(!initialized, "ai");
        owners = [_owners[0], _owners[1], _owners[2]];
        initialized = true;
    }

    function getSigner(bytes calldata _data, bytes calldata keys)
        public
        view
        returns (address)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(
            keys,
            (uint8, bytes32, bytes32)
        );
        return
            ecrecover(
                toEthSignedMessageHash(
                    keccak256(abi.encodePacked(this, chainId, _data))
                ),
                v,
                r,
                s
            );
    }

    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    // Set functions
    // verified
    function transferOwnership(
        address newOwner,
        bytes calldata signData,
        bytes calldata keys
    ) public onlyOwner validSignOfOwner(signData, keys, "transferOwnership") {
        uint256 index;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                index = i;
            }
        }
        address oldOwner = owners[index];
        owners[index] = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}