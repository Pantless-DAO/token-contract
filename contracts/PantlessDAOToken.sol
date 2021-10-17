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
    uint256 private _nextFounderTokenId;
    uint256 private _nextPublicTokenId;
    string private _baseTokenURI;
    address payable private _treasury;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 public constant PRICE_PER_TOKEN = 0.1 ether;
    uint256 public maxSupply = 2500;

    bool public isActive;

    mapping(address => uint256) public addressToNumClaimableFounderTokens;
    mapping(address => uint256) public addressToNumClaimablePublicTokens;

    mapping(address => uint256) public addressToNumMintableFounderTokens;

    event Claimed(address indexed claimer, uint256 indexed tokenId);
    event Minted(address indexed minter, uint256 indexed tokenId);

    constructor(string memory baseTokenURI, address payable treasury)
        ERC721("Pantless DAO Token", "PANTLESS")
    {
        _baseTokenURI = baseTokenURI;
        _treasury = treasury;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
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

    function claimFounderToken(address to, uint256 qty) external {
        require(isActive, "Not active");
        require(
            addressToNumClaimableFounderTokens[to] > qty,
            "Not enough tokens to claim"
        );

        addressToNumClaimableFounderTokens[to] -= qty;

        for (uint256 i = 0; i < qty; ++i) {
            _claimFounderToken(to);
        }
    }

    function _claimFounderToken(address to) internal {
        uint256 newTokenId = _nextFounderTokenId;
        ++_nextFounderTokenId;

        _mint(to, newTokenId);

        emit Claimed(to, newTokenId);
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

    function _claimPublicToken(address to) internal {
        uint256 newTokenId = _nextPublicTokenId;
        ++_nextPublicTokenId;

        _mint(to, newTokenId);

        emit Claimed(to, newTokenId);
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

    function _mintFounderToken(address to) internal {
        uint256 newTokenId = _nextFounderTokenId;
        ++_nextFounderTokenId;

        _mint(to, newTokenId);

        emit Minted(to, newTokenId);
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

    function _mintPublicToken(address to) internal {
        uint256 newTokenId = _nextPublicTokenId;
        ++_nextPublicTokenId;

        _mint(to, newTokenId);

        emit Minted(to, newTokenId);
    }

    function withdraw() external onlyRole(ADMIN_ROLE) {
        _treasury.transfer(address(this).balance);
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
