# DynamicPriceMint

DynamicPriceMint is an ERC721A token contract with dynamic pricing based on a Uniswap v3 pool price. It allows minting with both ERC20 tokens and ETH, with various configurable options for the contract owner.

## Features

- Minting with ERC20 tokens or ETH
- Dynamic pricing based on Uniswap v3 pool price
- Configurable minting options
- Token metadata reveal functionality
- Withdrawable contract balance and tokens

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) (which includes npm)
- [Hardhat](https://hardhat.org/)

### Installation

1. **Clone the Repository**

    ```bash
    git clone https://github.com/0xhttps/dynamicPriceMint.git
    cd dynamicPriceMint
    ```

2. **Install Dependencies**

    ```bash
    npm install --legacy-peer-deps
    ```

3. **Install Hardhat**

    ```bash
    npm install --save-dev hardhat
    ```

#### Note

Some manual changes to `@uniswap/v3-core` may be needed. I cannot remember lol

### Configuration

1. **Create Hardhat Project**: If not already done, initialize a Hardhat project.

    ```bash
    npx hardhat
    ```

2. **Update Hardhat Configuration**: Ensure your `hardhat.config.js` is properly configured to connect to the desired network. Here’s an example configuration for deployment on the Rinkeby testnet:

    ```javascript
    require("@nomiclabs/hardhat-waffle");
    require("@nomiclabs/hardhat-ethers");

    module.exports = {
      solidity: "0.8.25",
      networks: {
        rinkeby: {
          url: "https://rinkeby.infura.io/v3/YOUR_INFURA_PROJECT_ID",
          accounts: ["YOUR_PRIVATE_KEY"]
        }
      },
    };
    ```

    Replace `YOUR_INFURA_PROJECT_ID` with your Infura project ID and `YOUR_PRIVATE_KEY` with your Ethereum account private key.

### Deployment

1. **Compile the Contract**

    ```bash
    npx hardhat compile
    ```

2. **Deploy the Contract**: Run the deployment script.

    ```bash
    npx hardhat run scripts/deploy.js --network rinkeby
    ```

### Deployment Script

Ensure you have a `scripts` folder with a `deploy.js` file:

```javascript
// scripts/deploy.js

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const DynamicPriceMint = await ethers.getContractFactory("dynamicPriceMint");
  const dynamicPriceMint = await DynamicPriceMint.deploy();

  console.log("Contract address:", dynamicPriceMint.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### Functions

- `mintWithToken(uint256 amount)`: Allows minting with ERC20 tokens.
- `mintWithEth(uint256 amount)`: Allows minting with ETH.
- `ownerMintWithToken(uint256 amount)`: Allows the owner to mint tokens with ERC20 tokens.
- `reservedMint(address _addrs, uint256 amount)`: Allows the owner to mint reserved tokens to a specific address.
- `reveal()`: Reveals all tokens.
- `setIsMintActive(bool _isMintActive)`: Sets the mint active status.
- `setCanMintWithToken(bool _canMintWithToken)`: Sets the mint with token status.
- `setNotRevealedURI(string memory _notRevealedURI)`: Sets the URI for non-revealed tokens.
- `setBaseURI(string memory _newBaseURI)`: Sets the base URI for token metadata.
- `withdraw()`: Withdraws the contract balance to the owner.
- `withdrawTokens(IERC20 token)`: Withdraws ERC20 tokens from the contract to the owner.

### Events

- `Revealed(uint256 _tokenId)`: Emitted when tokens are revealed.
