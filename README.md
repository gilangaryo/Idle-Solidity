# AI Token Ecosystem

## Overview
This project consists of three Solidity smart contracts that work together to create and manage a token ecosystem. The system includes an AI interaction contract, a factory exchange for creating AI tokens, and the IDLEToken, which acts as the primary token in the ecosystem.

## Contracts

### 1. AIInteraction.sol
**Purpose:**
- This contract allows users to interact with an AI system.
- Requires users to hold a specific token to interact.
- Records interactions on-chain.

**Key Functions:**
- `setTokenAddress(address _tokenAddress)`: Updates the token required for AI interaction.
- `checkTokenBalance(address user)`: Returns the token balance of a user.
- `interactWithAI(string message, string response)`: Emits an event recording the AI interaction.

### 2. FactoryExchange.sol
**Purpose:**
- Creates and manages AI tokens.
- Facilitates buying and selling AI tokens using IDLE tokens.
- Implements pricing mechanisms.

**Key Features:**
- `createToken(string name, string symbol, uint256 idleAmount, string iconUrl, string description, string behaviour)`: Allows users to create custom AI tokens by locking IDLE tokens.
- `buyToken(address token, uint256 idleAmount)`: Allows users to purchase AI tokens with IDLE.
- `sellToken(address token, uint256 tokenAmount)`: Enables users to sell AI tokens back for IDLE.
- `getCurrentPrice(address token)`: Retrieves the current price of a given AI token.

### 3. IDLEToken.sol
**Purpose:**
- Serves as the main token of the ecosystem.
- Can be used to purchase AI tokens.
- Implements a claiming mechanism for daily rewards.

**Key Features:**
- `buyTokens(uint256 amount)`: Users can buy IDLE tokens with ETH.
- `claimTokens()`: Users can claim 100 IDLE tokens per day.
- `burn(uint256 value)`: The contract owner can burn tokens.
- `withdraw()`: The owner can withdraw ETH from the contract.

## Deployment & Usage

### Deployment
1. Deploy **IDLEToken.sol** first, as other contracts depend on it.
2. Deploy **FactoryExchange.sol**, passing the IDLE token address as a parameter.
3. Deploy **AIInteraction.sol**, specifying the AI token address required for interaction.

### Usage
- **Creating AI Tokens:** Use `createToken` in `FactoryExchange.sol`.
- **Buying AI Tokens:** Call `buyToken` with IDLE tokens.
- **Selling AI Tokens:** Use `sellToken` to exchange AI tokens back for IDLE.
- **Interacting with AI:** Ensure you hold AI tokens and call `interactWithAI` in `AIInteraction.sol`.

## License
This project is licensed under the MIT License.

