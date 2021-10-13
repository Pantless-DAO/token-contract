//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract PantlessDAOToken is
    Context,
    Ownable,
    ERC721Enumerable,
    ERC721Burnable
{
    uint256 private _nextTokenId;
    string private _baseTokenURI;
    address payable private _treasury;

    uint256 constant public PRICE_PER_TOKEN = 0.08 ether;
    uint256 constant public MAX_SUPPLY = 10000;

    bool public isClaimingEnabled;
    mapping(address => uint256) public numClaimableTokensByAddress;

    bool public isMintingEnabled;
    mapping(address => uint256) public numMintableTokensByAddress;

    event Claimed(address indexed claimer, uint256 indexed tokenId);
    event Minted(address indexed minter, uint256 indexed tokenId);

    constructor(string memory baseTokenURI, address payable treasury)
        ERC721("Pantless DAO Token", "PANTLESS")
    {
        _baseTokenURI = baseTokenURI;
        _treasury = treasury;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function toggleClaiming() external onlyOwner {
        isClaimingEnabled = !isClaimingEnabled;
    }

    function toggleMinting() external onlyOwner {
        isMintingEnabled = !isMintingEnabled;
    }

    function claim(address to) external {
        require(isClaimingEnabled, "Claiming is not enabled");
        require(_nextTokenId < MAX_SUPPLY, "All tokens are minted");
        require(numClaimableTokensByAddress[_msgSender()] > 0, "Already claimed");

        --numClaimableTokensByAddress[_msgSender()];

        uint256 newTokenId = _nextTokenId;
        ++_nextTokenId;

        _mint(to, newTokenId);

        emit Claimed(_msgSender(), newTokenId);
    }

    function mint(address to) external payable {
        require(isMintingEnabled, "Minting is not enabled");
        require(_nextTokenId < MAX_SUPPLY, "All tokens are minted");
        require(numMintableTokensByAddress[_msgSender()] > 0, "Already minted");
        require(msg.value == PRICE_PER_TOKEN, "Value is wrong");

        --numMintableTokensByAddress[_msgSender()];

        uint256 newTokenId = _nextTokenId;
        ++_nextTokenId;

        _mint(to, newTokenId);
        _treasury.transfer(PRICE_PER_TOKEN);

        emit Minted(_msgSender(), newTokenId);
    }

    function withdraw() external onlyOwner {
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
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
