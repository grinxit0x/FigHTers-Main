// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./helpers/Fighter.sol";
import "./helpers/IWhitelist.sol";

contract FigHTers is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC721BurnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 public precioMint = 0.1 ether;
    uint256 public maxSupply = 9630;
    //para el random ¬¬
    uint256 randNonce = 0;

    string baseTokenURI;

    Fighter[] public fighterList;

    // Whitelist contract instance
    IWhitelist whitelist;

    mapping(uint256 => address) public fightersToAddress;
    mapping(address => uint256) public fightersAddressCounter;

    modifier onlyOwnerOf(uint256 _tokenId) {
        require(fightersToAddress[_tokenId] == msg.sender);
        _;
    }

    // /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() {
    //     _disableInitializers();
    // }

    function initialize(string memory _uri, address _whitelistContract) public initializer {
        __ERC721_init("FigHTers", "FHT");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        baseTokenURI = _uri;
        whitelist = IWhitelist(_whitelistContract);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mintFighter(string memory _name)
        public
        payable
        onlyRole(MINTER_ROLE)
    {
        require(whitelist.whitelistedAddresses(msg.sender), "You are not whitelisted");
        
        uint256 tokenId = _tokenIdCounter.current();

        require(msg.value >= precioMint, "ETH sent is not correct");
        require(tokenId < maxSupply);
        require(
            fightersAddressCounter[msg.sender] < 1,
            "ERROR: This address has an NFT already."
        );

        //añadimos el nuevo fighter al array
        fighterList.push(
            Fighter(
                tokenId,
                _name,
                0,
                0,
                BattleStats(
                    uint16(_randMod(26)),
                    uint16(_randMod(26)),
                    uint16(_randMod(10)),
                    uint16(_randMod(26)),
                    uint16(_randMod(26)),
                    uint16(_randMod(10)),
                    uint16(_randMod(26)),
                    0,
                    0
                )
            )
        );

        _tokenIdCounter.increment();

        //add to mappings
        fightersToAddress[tokenId] = msg.sender;
        fightersAddressCounter[msg.sender] += 1;

        //mint
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, baseTokenURI);
    }

    function setPrecioMint(uint256 _newPrecio) public onlyRole(PAUSER_ROLE) {
        precioMint = _newPrecio;
    }

    function _randMod(uint256 _modulus) internal returns (uint256) {
        randNonce += 1;
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randNonce)
                )
            ) % _modulus;
    }

    function grantRoleMinter() public {
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function grantPauserRole(address _add) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(PAUSER_ROLE, _add);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    //esta función es importante ya que es la que enlaza la dirección gererada concateando strings
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        StringsUpgradeable.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
