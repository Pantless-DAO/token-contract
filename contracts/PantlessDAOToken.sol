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
    uint256 private _nextTokenId;
    string private _baseTokenURI;
    address payable private _treasury;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 public constant PRICE_PER_TOKEN = 0.1 ether;
    uint256 public maxSupply = 2500;

    bool public isActive;

    enum TokenType {
      PUBLIC,
      FOUNDER
    }
    mapping(uint256 => TokenType) public tokenIdToType;

    mapping(address => uint256) public addressToNumClaimableFounderTokens;
    mapping(address => uint256) public addressToNumClaimablePublicTokens;

    mapping(address => uint256) public addressToNumMintableFounderTokens;

    event FounderTokenClaimed(address indexed claimer, uint256 indexed tokenId);
    event PublicTokenClaimed(address indexed claimer, uint256 indexed tokenId);
    event FounderTokenMinted(address indexed minter, uint256 indexed tokenId);
    event PublicTokenMinted(address indexed minter, uint256 indexed tokenId);

    constructor(string memory baseTokenURI, address payable treasury)
        ERC721("Pantless DAO Token", "PANTLESS")
    {
        _baseTokenURI = baseTokenURI;
        _treasury = treasury;

        // TODO: Grant DEFAULT_ADMIN_ROLE & ADMIN_ROLE to Uncle Ether
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);

        _setupRole(ADMIN_ROLE, _msgSender());
    }

    function setBaseTokenURI(string memory baseTokenURI)
        external
        onlyRole(ADMIN_ROLE)
    {
        _baseTokenURI = baseTokenURI;
    }

    function setMaxSupply(uint256 maxSupply_) external onlyRole(ADMIN_ROLE) {
      maxSupply = maxSupply_;
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

    function setNumClaimablePublicTokensForAddresses(
        address[] calldata addresses,
        uint256[] calldata numClaimablePublicTokenss
    ) external {
        uint256 numAddresses = addresses.length;
        for (uint256 i = 0; i < numAddresses; ++i) {
            addressToNumClaimablePublicTokens[
                addresses[i]
            ] = numClaimablePublicTokenss[i];
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
            addressToNumClaimableFounderTokens[to] > qty,
            "Not enough quota"
        );

        addressToNumClaimableFounderTokens[to] -= qty;

        for (uint256 i = 0; i < qty; ++i) {
            _claimFounderToken(to);
        }
    }

    function claimPublicToken(address to, uint256 qty) external {
        require(isActive, "Not active");
        require(
            addressToNumClaimablePublicTokens[to] > qty,
            "Not enough quota"
        );

        addressToNumClaimablePublicTokens[to] -= qty;

        for (uint256 i = 0; i < qty; ++i) {
            _claimPublicToken(to);
        }
    }

    function mintFounderToken(address to, uint256 qty) external payable {
        require(isActive, "Not active");
        require(
            addressToNumMintableFounderTokens[to] > qty,
            "Not enough quota"
        );
        require(msg.value == qty * PRICE_PER_TOKEN, "Wrong value");

        addressToNumMintableFounderTokens[to] -= qty;
        _treasury.transfer(msg.value);

        for (uint256 i = 0; i < qty; ++i) {
            _mintFounderToken(to);
        }
    }

    function mintPublicToken(address to, uint256 qty) external payable {
        require(isActive, "Not active");
        require(totalSupply() + qty <= maxSupply, "No tokens left");
        require(msg.value == qty * PRICE_PER_TOKEN, "Wrong value");

        _treasury.transfer(msg.value);

        for (uint256 i = 0; i < qty; ++i) {
            _mintPublicToken(to);
        }
    }

    function withdraw() external onlyRole(ADMIN_ROLE) {
        _treasury.transfer(address(this).balance);
    }

    function _claimFounderToken(address to) internal {
        uint256 newTokenId = _nextTokenId;
        ++_nextTokenId;

        tokenIdToType[newTokenId] = TokenType.FOUNDER;
        _safeMint(to, newTokenId);

        emit FounderTokenClaimed(to, newTokenId);
    }

    function _claimPublicToken(address to) internal {
        uint256 newTokenId = _nextTokenId;
        ++_nextTokenId;

        _safeMint(to, newTokenId);

        emit PublicTokenClaimed(to, newTokenId);
    }

    function _mintFounderToken(address to) internal {
        uint256 newTokenId = _nextTokenId;
        ++_nextTokenId;

        tokenIdToType[newTokenId] = TokenType.FOUNDER;
        _safeMint(to, newTokenId);

        emit FounderTokenMinted(to, newTokenId);
    }

    function _mintPublicToken(address to) internal {
        uint256 newTokenId = _nextTokenId;
        ++_nextTokenId;

        _safeMint(to, newTokenId);

        emit PublicTokenMinted(to, newTokenId);
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
