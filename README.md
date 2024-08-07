# NFT Staking Smart Contract

This project implements a smart contract for staking NFTs that rewards users with ERC20 tokens. The contract is written in Solidity and uses the OpenZeppelin library for various functionalities such as ERC20, ERC721, and upgradeability.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Compilation](#compilation)
- [Deployment](#deployment)
- [Running Tests](#running-tests)
- [Contract Details](#contract-details)
- [License](#license)

## Prerequisites

Before you begin, ensure you have the following installed:

- Node.js
- npm (Node Package Manager)
- Hardhat

## Setup

1. Clone the repository:

   ```sh
   git clone https://github.com/harshpailkar/DZap_NFTStaking_Dapp.git
   cd DZap_NFTStaking_Dapp
   ```

2. Install dependencies:

   ```sh
   npm install
   ```

## Compilation

To compile the smart contracts, run the following command:

   ```sh
   npx hardhat compile
   ```

## Deployment

To deploy the contracts to the Hardhat local network, run the following commands:

1. Start the Hardhat local node: 

   ```sh
   npx hardhat node
   ```

2. Run the deploy script: 

   ```sh
   npx hardhat run scripts/deploy.js --network localhost
   ```

## Running Tests

To run the test file, execute the following command:

   ```sh
   npx hardhat test
   ```

## Contract Details

### NFTCollection.sol
This contract implements an ERC721 token that represents the NFT collection. It includes functions for minting new NFTs.

### RewardToken.sol
This contract implements an ERC20 token used for rewarding users who stake their NFTs.

### NFTStaking.sol
This contract allows users to stake their NFTs and earn reward tokens. It includes functionalities for staking, unstaking, claiming rewards, pausing/unpausing the contract and changing the staking configurations.
