// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract AIInteraction {
    address public tokenAddress; // Alamat token terkait (misalnya JKT)
    address public owner;

    event InteractionRecorded(
        address indexed user,
        string message,
        string response,
        uint256 timestamp
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        owner = msg.sender;
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
    }

    function checkTokenBalance(address user) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(user);
    }

    function interactWithAI(
        string memory message,
        string memory response
    ) public {
        require(
            IERC20(tokenAddress).balanceOf(msg.sender) > 0,
            "You need to own the token to interact with AI"
        );

        emit InteractionRecorded(msg.sender, message, response, block.timestamp);
    }
}
