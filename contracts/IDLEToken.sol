// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

/// @title IDLEToken - Token Utama Ekosistem Platform IDLE
/// @notice Token ini digunakan sebagai dasar dalam ekosistem IDLE, termasuk untuk membuat token kustom dan mengaktifkan AI Agent.
contract IDLEToken is ERC20, Ownable {
    // Harga token IDLE per unit dalam ETH
    uint256 public tokenPrice = 0.000001 ether;

    /// @notice Event yang dicatat setiap pembelian token
    /// @param buyer Alamat pembeli
    /// @param amount Jumlah token yang dibeli
    /// @param cost Biaya dalam ETH untuk pembelian tersebut
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);

    /// @notice Event untuk klaim token IDLE
    /// @param claimer Alamat yang mengklaim token
    /// @param amount Jumlah token yang diklaim
    /// @param timestamp Waktu klaim
    event TokensClaimed(address indexed claimer, uint256 amount, uint256 timestamp);

    /// @notice Mapping untuk melacak waktu klaim terakhir tiap alamat
    mapping(address => uint256) public lastClaimed;
    
    /// @notice Constructor untuk menginisialisasi kontrak token IDLE
    /// @param initialOwner Pemilik awal token dan kontrak
    /// @param initialSupply Pasokan awal token (tanpa desimal)
    constructor(
        address initialOwner,
        uint256 initialSupply
    ) ERC20("Idle", "IDL") Ownable(initialOwner) {
        _transferOwnership(initialOwner);
        _mint(initialOwner, initialSupply * 10 ** decimals());
    }

    /// @notice Membakar sejumlah token dari saldo pemilik (Owner)
    /// @param value Jumlah token yang akan dibakar (tanpa desimal)
    function burn(uint256 value) public onlyOwner {
        require(value <= type(uint256).max / (10 ** decimals()), "Amount too large");
        _burn(msg.sender, value * 10 ** decimals());
    }

    /// @notice Membeli token IDLE dengan ETH sesuai harga yang telah ditentukan
    /// @param amount Jumlah token yang ingin dibeli (tanpa desimal)
    function buyTokens(uint256 amount) public payable {
        require(amount > 0, "Amount must be greater than 0");

        uint256 cost = amount * tokenPrice;
        require(msg.value >= cost, "Insufficient ETH sent");

        uint256 tokenAmount = amount * 10 ** decimals();
        require(balanceOf(owner()) >= tokenAmount, "Not enough tokens in contract");

        _transfer(owner(), msg.sender, tokenAmount);

        emit TokensPurchased(msg.sender, tokenAmount, cost);
    }


    /// @notice Menarik saldo ETH yang terkumpul dalam kontrak ke alamat pemilik
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    /// @notice Fungsi klaim token IDLE
    /// Setiap wallet dapat mengklaim 100 token IDL per hari.
    function claimTokens() public {
        // Pastikan 1 hari telah berlalu sejak klaim terakhir
        require(block.timestamp >= lastClaimed[msg.sender] + 1 days, "You can only claim once per day");

        uint256 claimAmount = 100 * 10 ** decimals(); // 100 token IDL (dengan 18 desimal)
        lastClaimed[msg.sender] = block.timestamp;
        _mint(msg.sender, claimAmount);

        emit TokensClaimed(msg.sender, claimAmount, block.timestamp);
    }
}
