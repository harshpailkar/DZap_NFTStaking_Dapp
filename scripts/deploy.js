const {ethers, upgrades} = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();

    const RewardToken = await ethers.getContractFactory("RewardToken");
    const rewardToken = await RewardToken.deploy();
    await rewardToken.deployed()
    console.log("RewardToken deployed at: ", rewardToken.address);

    const NFTCollection = await ethers.getContractFactory("NFTCollection");
    const nftCollection = await NFTCollection.deploy();
    await nftCollection.deployed();
    console.log("NFTCollection deployed at: ", nftCollection.address);

    //as NFTStaking is an upgradable contract, we deployed using deployProxy to create the Proxy, ProxyAdmin and NFTStaking contracts.
    const NFTStaking = await ethers.getContractFactory("NFTStaking");
    const nftStaking = await upgrades.deployProxy(NFTStaking, [rewardToken.address, nftCollection.address, deployer.address], {initializer: 'intitalize'});
    await nftStaking.deployed();
    console.log("NFTStaking deployed at: ", nftStaking.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });