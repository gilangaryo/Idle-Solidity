// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FactoryExchange is Ownable {
    uint256 public tokenPrice = 0.000001 ether; 
    uint256 public constant TOKEN_PER_IDLE = 20; // 1 IDLE = 20 token AI
    uint256 public constant MAX_SUPPLY_AI = 30000 * 10 ** 18; // Maksimal 30,000 token AI
    IERC20 public idleToken;
    address[] public allTokens;

    // Hardcode: 1 ETH = 2000 USD, disimpan dalam 1e18 scale => 2000 * 1e18 = 2e21
    uint256 public constant HARDCODED_ETH_TO_USD_1e18 = 2000 * 1e18;

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
        string iconUrl;
        string description;
        string behaviour;
        uint256 openPrice;
        uint256 highPrice;
        uint256 lowPrice;
        uint256 closePrice;
    }

    mapping(address => TokenInfo) public tokenDetails;

    function convertWeiToUsd(uint256 weiAmount) public pure returns (uint256) {
        // Rumus: USD (1e18) = (weiAmount * HARDCODED_ETH_TO_USD_1e18) / 1e18
        // Jika weiAmount = 1e18 (1 ETH), maka:
        //   USD = (1e18 * 2000e18) / 1e18 = 2000e18
        //   artinya 2000 USD dalam skala 1e18
        return (weiAmount * HARDCODED_ETH_TO_USD_1e18) / 1e18;
    }


    function createToken(
        string memory name,
        string memory symbol,
        uint256 idleAmount,
        string memory iconUrl,
        string memory description,
        string memory behaviour
    ) public {
        require(idleAmount > 0, "IDLE amount must be greater than zero");

        idleToken.transferFrom(msg.sender, address(this), idleAmount);

        AIToken newToken = new AIToken(name, symbol, address(this));

        uint256 tokenAmount = idleAmount * TOKEN_PER_IDLE;
        
        require(tokenAmount <= MAX_SUPPLY_AI, "Exceeds maximum supply of AI tokens");

        AIToken(address(newToken)).mint(msg.sender, tokenAmount);
        
        // Hitung total ETH (wei) yang setara IDLE user
        // tokenPrice = 0.000001 ether => 1 IDLE => 0.000001 ETH
        // => totalEthWei = idleAmount * 0.000001 ether
        uint256 totalEthWei = idleAmount * tokenPrice;

        // Konversi totalEthWei ke USD (skala 1e18)
        uint256 totalUsd1e18 = convertWeiToUsd(totalEthWei);

        // Hitung harga awal per 1 AI token dalam USD (skala 1e18)
        // initialPriceUsd1e18 = totalUsd1e18 / tokenAmount
        uint256 initialPriceUsd1e18 = 0;
        if (tokenAmount > 0) {
            initialPriceUsd1e18 = totalUsd1e18 / tokenAmount;
        }

        // Simpan data token ke struct
        // totalSupply disimpan sebagai "token utuh" => tokenAmount / 1e18
        // Harga-harga (open, high, low, close) disimpan dalam 1e18 scale => mewakili USD
        tokenDetails[address(newToken)] = TokenInfo(
            name,
            symbol,
            tokenAmount / 10**18,
            msg.sender,
            block.timestamp,
            iconUrl,
            description,
            behaviour,
            initialPriceUsd1e18, // openPrice (USD, 1e18)
            initialPriceUsd1e18, // highPrice
            initialPriceUsd1e18, // lowPrice
            initialPriceUsd1e18  // closePrice
        );

        // Tambahkan token baru ke array
        allTokens.push(address(newToken));

        emit TokenCreated(msg.sender, address(newToken), block.timestamp);
    }


    function buyToken(address token, uint256 idleAmount) public {
        require(idleAmount > 0, "IDLE amount must be greater than zero");

        TokenInfo storage tokenInfo = tokenDetails[token];
        require(tokenInfo.owner != address(0), "Token does not exist");

        uint256 tokenAmount = calculateTokensForIDLE(token, idleAmount);
        require(tokenInfo.totalSupply + tokenAmount <= MAX_SUPPLY_AI, "Max supply reached");

        idleToken.transferFrom(msg.sender, address(this), idleAmount);

        AIToken(token).mint(msg.sender, tokenAmount);

        tokenInfo.totalSupply += tokenAmount;

        uint256 currentPrice = getCurrentPrice(token);
        updateOHLC(token, currentPrice);

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

        tokenInfo.totalSupply -= tokenAmount;

        idleToken.transfer(msg.sender, idleAmount);

        uint256 currentPrice = getCurrentPrice(token);
        updateOHLC(token, currentPrice);

        emit TokenSold(msg.sender, token, tokenAmount, idleAmount);
    }

    function getCurrentPrice(address token) public view returns (uint256) {
        TokenInfo storage tokenInfo = tokenDetails[token];
        uint256 supply = tokenInfo.totalSupply / 10 ** 18;

        return 0.000001 ether + ((supply * 0.000001 ether) / 100000);
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

    function getMarketCap(address token) public view returns (uint256) {
        TokenInfo storage tokenInfo = tokenDetails[token];
        require(tokenInfo.owner != address(0), "Token does not exist");

        uint256 currentPrice = getCurrentPrice(token);
        uint256 marketCap = tokenInfo.totalSupply * currentPrice / 10**18;

        return marketCap;
    }

    function updateOHLC(address token, uint256 currentPrice) internal {
        TokenInfo storage tokenInfo = tokenDetails[token];

        if (currentPrice > tokenInfo.highPrice) {
            tokenInfo.highPrice = currentPrice;
        }
        if (currentPrice < tokenInfo.lowPrice) {
            tokenInfo.lowPrice = currentPrice;
        }
        tokenInfo.closePrice = currentPrice;
    }
    function getAllIssue() public view returns (TokenInfo[] memory, address[] memory, uint256[] memory) {
        uint256 tokenCount = allTokens.length;
        TokenInfo[] memory details = new TokenInfo[](tokenCount);
        address[] memory tokenAddresses = new address[](tokenCount);
        uint256[] memory ids = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            address tokenAddress = allTokens[i];
            details[i] = tokenDetails[tokenAddress];
            tokenAddresses[i] = tokenAddress;
            ids[i] = i + 1;
        }

        return (details, tokenAddresses, ids);
    }

    function allIssues() public view returns (string[][] memory) {
        uint256 tokenCount = allTokens.length;
        string[][] memory result = new string[][](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            address tokenAddress = allTokens[i];
            TokenInfo memory token = tokenDetails[tokenAddress];

            string[] memory tokenData = new string[](9);
            tokenData[0] = Strings.toString(i);
            tokenData[1] = token.name;
            tokenData[2] = Strings.toString(token.totalSupply);
            tokenData[3] = token.symbol;
            tokenData[4] = token.description;
            tokenData[5] = token.iconUrl;
            tokenData[6] = Strings.toString(token.createdAt);
            tokenData[7] = "true"; // Adjust based on open/close condition if needed
            tokenData[8] = Strings.toHexString(uint256(uint160(token.owner)), 20);

            result[i] = tokenData;
        }

        return result;
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
