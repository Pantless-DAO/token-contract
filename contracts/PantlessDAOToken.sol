//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract PantlessDAOToken is
    Context,
    AccessControlEnumerable,
    ERC1155,
    ERC1155Burnable,
    ERC1155Supply
{
    struct TokenData {
        uint256 offset;
        uint256 maxSupply;
        uint256[] variationToMaxSupply;
        mapping(address => uint256) addressToNumClaimableTokens;
        mapping(address => uint256) addressToNumMintableTokens;
        uint256 pricePerToken;
    }

    address payable private _treasury;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    bool public isActive = false;

    TokenData[256] public tokenTypeToData;
    uint8[] public tokenIdToType;

    event TokenClaimed(address indexed to, uint256 indexed tokenId);
    event TokenMinted(address indexed to, uint256 indexed tokenId);

    constructor(string memory uri, address payable treasury) ERC1155(uri) {
        _treasury = treasury;

        // TODO: Grant DEFAULT_ADMIN_ROLE & ADMIN_ROLE to Uncle Ether instead of
        // the deployer.
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());

        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function setUri(string memory uri) external onlyRole(ADMIN_ROLE) {
        _setURI(uri);
    }

    function toggleIsActive() external onlyRole(ADMIN_ROLE) {
        isActive = !isActive;
    }

    function setDataForTokenType(
        uint256 offset,
        uint256[] calldata variationToMaxSupply,
        uint256 pricePerToken,
        uint8 tokenType
    ) external onlyRole(ADMIN_ROLE) {
        TokenData storage tokenData = tokenTypeToData[tokenType];
        tokenData.offset = offset;
        tokenData.variationToMaxSupply = variationToMaxSupply;
        uint256 numVariations = tokenData.variationToMaxSupply.length;
        for (uint256 i = 0; i < numVariations; ++i) {
            tokenData.maxSupply += tokenData.variationToMaxSupply[i];
        }
        for (uint256 i = 0; i < numVariations; ++i) {
            tokenIdToType[tokenData.offset + i] = tokenType;
        }
        tokenData.pricePerToken = pricePerToken;
    }

    function setNumClaimableTokensForAddresses(
        address[] calldata addresses,
        uint256[] calldata numClaimableTokenss,
        uint8 tokenType
    ) external onlyRole(ADMIN_ROLE) {
        require(
            addresses.length == numClaimableTokenss.length,
            "Lengths not match"
        );
        TokenData storage tokenData = tokenTypeToData[tokenType];
        uint256 numAddresses = addresses.length;
        for (uint256 i = 0; i < numAddresses; ++i) {
            tokenData.addressToNumClaimableTokens[
                addresses[i]
            ] = numClaimableTokenss[i];
        }
    }

    function setNumMintableTokensForAddresses(
        address[] calldata addresses,
        uint256[] calldata numMintableTokenss,
        uint8 tokenType
    ) external onlyRole(ADMIN_ROLE) {
        require(
            addresses.length == numMintableTokenss.length,
            "Lengths not match"
        );
        TokenData storage tokenData = tokenTypeToData[tokenType];
        uint256 numAddresses = addresses.length;
        for (uint256 i = 0; i < numAddresses; ++i) {
            tokenData.addressToNumMintableTokens[
                addresses[i]
            ] = numMintableTokenss[i];
        }
    }

    function claimToken(
        address to,
        uint256 qty,
        uint8 tokenType
    ) external {
        require(isActive, "Not active");
        TokenData storage tokenData = tokenTypeToData[tokenType];
        uint256 offset = tokenData.offset;
        uint256[] memory variationToMaxSupply = tokenData.variationToMaxSupply;
        uint256 numVariations = variationToMaxSupply.length;
        uint256 tokenTypeTotalSupply = 0;
        for (uint256 i = 0; i < numVariations; ++i) {
            tokenTypeTotalSupply += totalSupply(offset + i);
        }
        require(
            tokenTypeTotalSupply + qty <= tokenData.maxSupply,
            "No tokens left"
        );
        require(
            qty <= tokenData.addressToNumClaimableTokens[to],
            "Not enough quota"
        );

        tokenData.addressToNumClaimableTokens[to] -= qty;

        for (uint256 i = 0; i < qty; ++i) {
            uint256 newTokenId = 0;
            bool isFound = false;
            while (!isFound) {
                newTokenId = _randomNumberBetween(
                    offset,
                    offset + numVariations,
                    i
                );
                isFound =
                    totalSupply(newTokenId) < variationToMaxSupply[newTokenId];
            }
            _mint(to, newTokenId, 1, "");

            emit TokenClaimed(to, newTokenId);
        }
    }

    function mintToken(
        address to,
        uint256 qty,
        uint8 tokenType,
        bool needWhitelist
    ) external payable {
        require(isActive, "Not active");
        TokenData storage tokenData = tokenTypeToData[tokenType];
        uint256 offset = tokenData.offset;
        uint256[] memory variationToMaxSupply = tokenData.variationToMaxSupply;
        uint256 numVariations = variationToMaxSupply.length;
        uint256 tokenTypeTotalSupply = 0;
        for (uint256 i = 0; i < numVariations; ++i) {
            tokenTypeTotalSupply += totalSupply(offset + i);
        }
        require(
            tokenTypeTotalSupply + qty <= tokenData.maxSupply,
            "No tokens left"
        );

        if (needWhitelist) {
            require(
                qty <= tokenData.addressToNumMintableTokens[to],
                "Not enough quota"
            );

            tokenData.addressToNumMintableTokens[to] -= qty;
        }

        require(msg.value == qty * tokenData.pricePerToken, "Wrong value");

        _treasury.transfer(msg.value);

        for (uint256 i = 0; i < qty; ++i) {
            uint256 newTokenId = 0;
            bool isFound = false;
            while (!isFound) {
                newTokenId = _randomNumberBetween(
                    offset,
                    offset + numVariations,
                    i
                );
                isFound =
                    totalSupply(newTokenId) < variationToMaxSupply[newTokenId];
            }
            _mint(to, newTokenId, 1, "");

            emit TokenMinted(to, newTokenId);
        }
    }

    function withdraw() external onlyRole(ADMIN_ROLE) {
        _treasury.transfer(address(this).balance);
    }

    function _randomNumberBetween(
        uint256 min,
        uint256 max,
        uint256 n
    ) internal view returns (uint256) {
        uint256 range = max - min;
        return
            min +
            (uint256(
                keccak256(
                    abi.encodePacked(
                        n,
                        block.number,
                        blockhash(block.number - 1),
                        _msgSender(),
                        block.timestamp
                    )
                )
            ) % range);
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._mint(account, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._mintBatch(to, ids, amounts, data);
    }

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal override(ERC1155, ERC1155Supply) {
        super._burn(account, id, amount);
    }

    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal override(ERC1155, ERC1155Supply) {
        super._burnBatch(account, ids, amounts);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable, ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
