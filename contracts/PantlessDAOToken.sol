//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract PantlessDAOToken is
    Context,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable
{
    string private _baseTokenURI;
    address payable private _treasury;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 public constant PRICE_PER_TOKEN = 0.1 ether;

    uint256 public constant CLAIMABLE_FOUNDER_TOKEN_END_ID = 125;
    uint256 public constant MINTABLE_FOUNDER_TOKEN_END_ID = 250;
    uint256 public constant CLAIMABLE_STANDARD_TOKEN_END_ID = 1250;
    uint256 public constant MINTABLE_STANDARD_TOKEN_END_ID = 2500;

    uint256 public nextClaimableFounderTokenId = 1;
    uint256 public nextMintableFounderTokenId;
    uint256 public nextClaimableStandardTokenId;
    uint256 public nextMintableStandardTokenId;

    bool public isActive = false;

    mapping(address => uint256) public addressToNumClaimableFounderTokens;
    mapping(address => uint256) public addressToNumClaimableStandardTokens;

    mapping(address => uint256) public addressToNumMintableFounderTokens;

    event FounderTokenClaimed(address indexed to, uint256 indexed tokenId);
    event StandardTokenClaimed(address indexed to, uint256 indexed tokenId);
    event FounderTokenMinted(address indexed to, uint256 indexed tokenId);
    event StandardTokenMinted(address indexed to, uint256 indexed tokenId);

    constructor(string memory baseTokenURI, address payable treasury)
        ERC721("Pantless DAO Token", "PANTLESS")
    {
        _baseTokenURI = baseTokenURI;
        _treasury = treasury;

        // TODO: Grant DEFAULT_ADMIN_ROLE & ADMIN_ROLE to Uncle Ether
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());

        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);

        nextMintableFounderTokenId = CLAIMABLE_FOUNDER_TOKEN_END_ID + 1;
        nextClaimableStandardTokenId = MINTABLE_FOUNDER_TOKEN_END_ID + 1;
        nextMintableStandardTokenId = CLAIMABLE_STANDARD_TOKEN_END_ID + 1;
    }

    function setBaseTokenURI(string memory baseTokenURI)
        external
        onlyRole(ADMIN_ROLE)
    {
        _baseTokenURI = baseTokenURI;
    }

    function toggleIsActive() external onlyRole(ADMIN_ROLE) {
        isActive = !isActive;
    }

    function setNumClaimableFounderTokensForAddresses(
        address[] calldata addresses,
        uint256[] calldata numClaimableFounderTokenss
    ) external {
        uint256 numAddresses = addresses.length;
        for (uint256 i = 0; i < numAddresses; ++i) {
            addressToNumClaimableFounderTokens[
                addresses[i]
            ] = numClaimableFounderTokenss[i];
        }
    }

    function setNumClaimableStandardTokensForAddresses(
        address[] calldata addresses,
        uint256[] calldata numClaimableStandardTokenss
    ) external {
        uint256 numAddresses = addresses.length;
        for (uint256 i = 0; i < numAddresses; ++i) {
            addressToNumClaimableStandardTokens[
                addresses[i]
            ] = numClaimableStandardTokenss[i];
        }
    }

    function setNumMintableFounderTokensForAddresses(
        address[] calldata addresses,
        uint256[] calldata numMintableFounderTokenss
    ) external {
        uint256 numAddresses = addresses.length;
        for (uint256 i = 0; i < numAddresses; ++i) {
            addressToNumMintableFounderTokens[
                addresses[i]
            ] = numMintableFounderTokenss[i];
        }
    }

    function claimFounderToken(address to, uint256 qty) external {
        require(isActive, "Not active");
        require(
            nextClaimableFounderTokenId + qty - 1 <=
                CLAIMABLE_FOUNDER_TOKEN_END_ID,
            "No tokens left"
        );
        require(
            qty <= addressToNumClaimableFounderTokens[to],
            "Not enough quota"
        );

        addressToNumClaimableFounderTokens[to] -= qty;

        for (uint256 i = 0; i < qty; ++i) {
            _claimFounderToken(to);
        }
    }

    function claimStandardToken(address to, uint256 qty) external {
        require(isActive, "Not active");
        require(
            nextClaimableStandardTokenId + qty - 1 <=
                CLAIMABLE_STANDARD_TOKEN_END_ID,
            "No tokens left"
        );
        require(
            qty <= addressToNumClaimableStandardTokens[to],
            "Not enough quota"
        );

        addressToNumClaimableStandardTokens[to] -= qty;

        for (uint256 i = 0; i < qty; ++i) {
            _claimStandardToken(to);
        }
    }

    function mintFounderToken(address to, uint256 qty) external payable {
        require(isActive, "Not active");
        require(
            nextMintableFounderTokenId + qty - 1 <=
                MINTABLE_FOUNDER_TOKEN_END_ID,
            "No tokens left"
        );
        require(
            qty <= addressToNumMintableFounderTokens[to],
            "Not enough quota"
        );
        require(msg.value == qty * PRICE_PER_TOKEN, "Wrong value");

        addressToNumMintableFounderTokens[to] -= qty;
        _treasury.transfer(msg.value);

        for (uint256 i = 0; i < qty; ++i) {
            _mintFounderToken(to);
        }
    }

    function mintStandardToken(address to, uint256 qty) external payable {
        require(isActive, "Not active");
        require(
            nextMintableStandardTokenId + qty - 1 <=
                MINTABLE_STANDARD_TOKEN_END_ID,
            "No tokens left"
        );
        require(msg.value == qty * PRICE_PER_TOKEN, "Wrong value");

        _treasury.transfer(msg.value);

        for (uint256 i = 0; i < qty; ++i) {
            _mintStandardToken(to);
        }
    }

    function withdraw() external onlyRole(ADMIN_ROLE) {
        _treasury.transfer(address(this).balance);
    }

    function _claimFounderToken(address to) internal {
        uint256 newTokenId = nextClaimableFounderTokenId;
        ++nextClaimableFounderTokenId;

        _safeMint(to, newTokenId);

        emit FounderTokenClaimed(to, newTokenId);
    }

    function _claimStandardToken(address to) internal {
        uint256 newTokenId = nextClaimableStandardTokenId;
        ++nextClaimableStandardTokenId;

        _safeMint(to, newTokenId);

        emit StandardTokenClaimed(to, newTokenId);
    }

    function _mintFounderToken(address to) internal {
        uint256 newTokenId = nextMintableFounderTokenId;
        ++nextMintableFounderTokenId;

        _safeMint(to, newTokenId);

        emit FounderTokenMinted(to, newTokenId);
    }

    function _mintStandardToken(address to) internal {
        uint256 newTokenId = nextMintableStandardTokenId;
        ++nextMintableStandardTokenId;

        _safeMint(to, newTokenId);

        emit StandardTokenMinted(to, newTokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
