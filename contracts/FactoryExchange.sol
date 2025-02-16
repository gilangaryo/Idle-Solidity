// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FactoryExchange is Ownable {
    uint256 public constant TOKEN_PER_IDLE = 150000; // 1 IDLE = 150000 token AI
    IERC20 public idleToken;
    address[] public allTokens;

    constructor(address initialOwner, address _idleToken) Ownable(initialOwner) {
        idleToken = IERC20(_idleToken);
    }

    mapping(address => address) public userTokens;

    event TokenCreated(address indexed creator, address tokenAddress, uint256 timestamp);
    event TokenPurchased(address indexed buyer, address token, uint256 amount);
    event TokenSold(address indexed seller, address token, uint256 amount, uint256 idleReceived);

    struct TokenInfo {
        string name;
        string symbol;
        uint256 totalSupply;
        address owner;
        uint256 createdAt;
    }

    mapping(address => TokenInfo) public tokenDetails;

    function createToken(
        string memory name,
        string memory symbol,
        uint256 idleAmount
    ) public {
        require(idleAmount > 0, "IDLE amount must be greater than zero");

        // Transfer IDLE dari user ke kontrak sebagai reserve awal
        idleToken.transferFrom(msg.sender, address(this), idleAmount);

        // Buat token AI
        AIToken newToken = new AIToken(name, symbol, address(this));

        // Simpan info token baru, supply = 0
        userTokens[msg.sender] = address(newToken);
        tokenDetails[address(newToken)] = TokenInfo(name, symbol, 0, msg.sender, block.timestamp);
        allTokens.push(address(newToken));

        emit TokenCreated(msg.sender, address(newToken), block.timestamp);
    }

    function buyToken(address token, uint256 idleAmount) public {
        require(idleAmount > 0, "IDLE amount must be greater than zero");

        TokenInfo storage tokenInfo = tokenDetails[token];
        require(tokenInfo.owner != address(0), "Token does not exist");

        uint256 tokenAmount = calculateTokensForIDLE(token, idleAmount);

        idleToken.transferFrom(msg.sender, address(this), idleAmount);

        AIToken(token).mint(msg.sender, tokenAmount);

        tokenInfo.totalSupply += tokenAmount / 10**18;

        emit TokenPurchased(msg.sender, token, tokenAmount);
    }

    function sellToken(address token, uint256 tokenAmount) public {
        require(tokenAmount > 0, "Token amount must be greater than zero");

        TokenInfo storage tokenInfo = tokenDetails[token];
        require(tokenInfo.owner != address(0), "Token does not exist");

        uint256 idleAmount = calculateIDLEForTokens(token, tokenAmount);
        require(idleToken.balanceOf(address(this)) >= idleAmount, "Not enough IDLE in reserve");

        AIToken(token).transferFrom(msg.sender, address(this), tokenAmount);
        AIToken(token).burn(tokenAmount);

        tokenInfo.totalSupply -= tokenAmount / 10**18;

        idleToken.transfer(msg.sender, idleAmount);

        emit TokenSold(msg.sender, token, tokenAmount, idleAmount);
    }

    function getCurrentPrice(address token) public view returns (uint256) {
        TokenInfo storage tokenInfo = tokenDetails[token];
        uint256 supply = tokenInfo.totalSupply;

        return 0.00003 ether + ((supply * 0.00003 ether) / 100000);
    }

    function calculateTokensForIDLE(address token, uint256 idleAmount) public view returns (uint256) {
        uint256 pricePerToken = getCurrentPrice(token);
        return (idleAmount * 10**18) / pricePerToken; 
    }

    function calculateIDLEForTokens(address token, uint256 tokenAmount) public view returns (uint256) {
        uint256 pricePerToken = getCurrentPrice(token);
        return (tokenAmount * pricePerToken) / 10**18;
    }

    function withdrawIdle(uint256 amount) public onlyOwner {
        idleToken.transfer(owner(), amount);
    }

    function getAllTokens() public view returns (address[] memory) {
        return allTokens;
    }
}

contract AIToken is ERC20, Ownable {
    constructor(
        string memory name_,
        string memory symbol_,
        address factory
    ) ERC20(name_, symbol_) Ownable(factory) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) public onlyOwner {
        _burn(address(this), amount);
    }
}
