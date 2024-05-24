// SPDX-License-Identifier: MIT

/*
    Created by 0xhttps
    https://github.com/0xhttps
*/

pragma solidity ^0.8.25;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";

/**
 * @title dynamicPriceMint
 * @dev ERC721A token with dynamic pricing based on Uniswap v3 pool price and minting with ERC20 tokens or ETH.
 */
contract dynamicPriceMint is ERC721A, Ownable {
    // Uniswap v3 pool address
    address public immutable poolAddress = 0x026d09A6995F2d3250D9728e2BD58c6c2B953955;
    // ERC20 token address used for minting
    IERC20 erc20Token = IERC20(0x3eeec801CEf575B876d253AB06d75251F67D827d);

    // Initial price in wei
    uint256 price = 100000000000000;
    // Maximum supply of NFTs
    uint256 public constant maxSupply = 10;

    using Strings for uint256;

    // Base URI for token metadata
    string public baseURI;
    // URI for non-revealed token metadata
    string public notRevealedUri;

    // Mapping to track mint count per address
    mapping(address => uint256) public addrMintCount;
    // Mapping to track token amount used per address
    mapping(address => uint256) public addrTokenAmountUsed;

    // Flag to check if tokens are revealed
    bool public revealed = false;
    // Flag to check if minting is active
    bool public isMintActive = true;
    // Flag to check if minting with token is allowed
    bool public canMintWithToken = true;

    // Event emitted when tokens are revealed
    event Revealed(uint256 _tokenId);

    /**
     * @dev Slot0 struct to store Uniswap v3 pool data.
     */
    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
        uint16 observationIndex;
        uint16 observationCardinality;
        uint16 observationCardinalityNext;
        uint8 feeProtocol;
        bool unlocked;
    }

    constructor() ERC721A("name", "symbol") {}

    /**
     * @dev Internal function to perform multiplication and division with precision.
     * @param a Multiplicand
     * @param b Multiplier
     * @param denominator Divisor
     * @return result Result of (a * b) / denominator
     */
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256) {
        uint256 result = a * b;
        return result / denominator;
    }

    /**
     * @dev Returns the mint price in ERC20 tokens based on the current Uniswap v3 pool price.
     * @param amount Number of tokens to mint
     * @return fullPrice Price in ERC20 tokens
     */
    function getTokenMintPrice(uint amount) public view returns (uint) {
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();
        uint256 numerator1 = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        uint256 numerator2 = 10**18;
        uint256 returnPrice = FullMath.mulDiv(numerator1, numerator2, 1 << 192);
        uint256 fullPrice = ((price * amount) / returnPrice) * 10**18;
        return fullPrice;
    }

    /**
     * @dev Allows minting with ERC20 tokens.
     * @param amount Number of tokens to mint
     */
    function mintWithToken(uint256 amount) external payable {
        uint mintPrice = getTokenMintPrice(amount);
        require(isMintActive, "Mint is not active");
        require(msg.sender == tx.origin, "Sender cannot be a smart contract");
        require(canMintWithToken, "Cannot mint with token currently");
        require(totalSupply() + amount <= maxSupply, "Cannot exceed max supply");
        require(mintPrice > 0, "Not enough tokens");
        require(erc20Token.allowance(msg.sender, address(this)) >= mintPrice, "Allowance must be greater than mintPrice");
        require(erc20Token.transferFrom(msg.sender, address(this), mintPrice), "Must transfer token to mint");
        addrMintCount[msg.sender] += amount;
        addrTokenAmountUsed[msg.sender] += mintPrice;
        _internalMint(msg.sender, amount);
    }

    /**
     * @dev Allows minting with ETH.
     * @param amount Number of tokens to mint
     */
    function mintWithEth(uint256 amount) external payable {
        require(isMintActive, "Mint is not active");
        require(msg.sender == tx.origin, "Sender cannot be a smart contract");
        require(msg.value >= price * amount, "Not enough ETH");
        require(totalSupply() + amount <= maxSupply, "Cannot exceed max supply");
        addrMintCount[msg.sender] += amount;
        _internalMint(msg.sender, amount);
    }

    /**
     * @dev Allows the owner to mint tokens with ERC20 tokens.
     * @param amount Number of tokens to mint
     */
    function ownerMintWithToken(uint256 amount) external payable onlyOwner {
        uint mintPrice = getTokenMintPrice(amount);
        require(totalSupply() + amount <= maxSupply, "Cannot exceed max supply");
        require(mintPrice > 0, "Not enough tokens");
        require(erc20Token.allowance(msg.sender, address(this)) >= mintPrice, "Allowance must be greater than mintPrice");
        require(erc20Token.transferFrom(msg.sender, address(this), mintPrice), "Must transfer token to mint");
        addrMintCount[msg.sender] += amount;
        addrTokenAmountUsed[msg.sender] += mintPrice;
        _internalMint(msg.sender, amount);
    }

    /**
     * @dev Allows the owner to mint reserved tokens to a specific address.
     * @param _addrs Address to mint to
     * @param amount Number of tokens to mint
     */
    function reservedMint(address _addrs, uint256 amount) public onlyOwner {
        require(amount <= maxSupply, "Not enough NFTs left");
        _internalMint(_addrs, amount);
    }

    /**
     * @dev Internal function to perform the actual minting.
     * @param to Address to mint to
     * @param amount Number of tokens to mint
     * @return amount Number of tokens minted
     */
    function _internalMint(address to, uint256 amount) private returns (uint256) {
        _safeMint(to, amount);
        return amount;
    }

    /**
     * @dev Returns the token URI for a given token ID.
     * @param tokenId Token ID
     * @return Token URI
     */
    function tokenURI(uint256 tokenId) public view override(ERC721A) returns(string memory) {
        require(_exists(tokenId), "Nonexistent token");
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Reveals all tokens.
     */
    function reveal() public onlyOwner {
        revealed = true;
    }

    /**
     * @dev Sets the mint active status.
     * @param _isMintActive New mint active status
     */
    function setIsMintActive(bool _isMintActive) public onlyOwner {
        isMintActive = _isMintActive;
    }

    /**
     * @dev Sets the mint with token status.
     * @param _canMintWithToken New mint with token status
     */
    function setCanMintWithToken(bool _canMintWithToken) public onlyOwner {
        canMintWithToken = _canMintWithToken;
    }

    /**
     * @dev Sets the URI for non-revealed tokens.
     * @param _notRevealedURI New URI for non-revealed tokens
     */
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    /**
     * @dev Sets the base URI for token metadata.
     * @param _newBaseURI New base URI
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @dev Withdraws the contract balance to the owner.
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @dev Withdraws ERC20 tokens from the contract to the owner.
     * @param token ERC20 token to withdraw
     */
    function withdrawTokens(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }
}
