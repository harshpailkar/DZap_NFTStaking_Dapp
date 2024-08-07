const {expect} = require("chai");
const hre = require("hardhat");

describe("NFTStaking", function () {
  let RewardToken, rewardToken, NFTCollection, nftCollection, NFTStaking, nftStaking;
  let owner, address1, address2;
  const rewardsPerBlock = 100;
  const unbondingPeriod = 3 * 24 * 60 * 60;
  const rewardDelayPeriod = 24 * 60 * 60;

  this.beforeEach(async function () {
    [owner, address1, address2, _] = await hre.ethers.getSigners();

    RewardToken = await ethers.getContractFactory("RewardToken");
    rewardToken = await RewardToken.deploy();
    await rewardToken.deployed()

    NFTCollection = await ethers.getContractFactory("NFTCollection");
    nftCollection = await NFTCollection.deploy();
    await nftCollection.deployed();

    NFTStaking = await ethers.getContractFactory("NFTStaking");
    nftStaking = await upgrades.deployProxy(NFTStaking, [rewardToken.address, nftCollection.address, deployer.address], {initializer: 'intitalize'});
    await nftStaking.deployed();

    await nftCollection.mint(address1.address, 1);
    await nftCollection.mint(address1.address, 2);
    await rewardToken.mint(nftStaking.address, hre.ethers.utils.parseEther("1000"));
  });

  it("Should allow staking of NFTs", async function () {
    await nftCollection.connect(address1).approve(nftStaking.address, 1);
    await nftStaking.connect(address1).stake(1);

    const stakedTokens = await nftStaking.getStakedTokens(address1.address);
    expect(stakedTokens.length).to.equal(1);
    expect(stakedTokens[0].tokenId).to.equal(1);
  });

  it("Should allow unstaking of NFTs after the unbonding period", async function () {
    await nftCollection.connect(address1).approve(nftStaking.address, 1);
    await nftStaking.connect(address1).stake(1);
    await nftStaking.connect(address1).unstake(1);
    await expect(nftStaking.connect(address1).withdraw(1)).to.be.revertedWith("Please wait till the unbonding period is over!");

    await hre.network.provider.send("evm_increaseTime", [unbondingPeriod]);
    await hre.network.provider.send("evm_mine");

    await nftStaking.connect(address1).withdraw(1);
    expect(await nftCollection.ownerOf(1).to.equal(address1.address));
  });

  it("Should allow claiming of rewards after delay period", async function () {
    await nftCollection.connect(address1).approve(nftStaking.address, 1);
    await nftStaking.connect(address1).stake(1);

    for(let i = 0; i < 10; i++) {
      await hre.network.provider.send("evm_mine");
    }

    await expect(nftStaking.connect(address1).claimRewards()).to.be.revertedWith("Please wait till the delay period is over to collect your rewards!");

    await hre.network.provider.send("evm_increaseTime", [rewardDelayPeriod]);
    await hre.network.provider.send("evm_mine");

    await nftStaking.connect(address1).claimRewards();
    expect(await rewardToken.balanceOf(address1.address)).to.equal(rewardsPerBlock * 10);
  });

  it("Should allow pausing and unpausing by the owner", async function () {
    await nftStaking.pause();
    await expect(nftStaking.connect(address1).stake(1)).to.be.revertedWith("Pausable: paused");

    await nftStaking.unpause();
    await nftCollection.connect(address1).approve(nftStaking.address, 1);
    await nftStaking.connect(address1).stake(1);

    const stakedTokens = await nftStaking.getStakedTokens(address1.address);
    expect(stakedTokens.length).to.equal(1);
    expect(stakedTokens[0].tokenId).to.equal(1);
  });

  it("Should allow owner to update rewardsPerBlock", async function () {
    await nftStaking.updateRewardsPerBlock(200);
    expect(await nftStaking.rewardsPerBlock()).to.equal(200);
  });

  it("Should allow owner to update unbondingPeriod", async function () {
    await nftStaking.updateUnbondingPeriod(2 * 24 * 60 * 60);
    expect(await nftStaking.unbondingPeriod()).to.equal(2 * 24 * 60 * 60);
  });

  it("Should allow owner to update rewardDelayPeriod", async function () {
    await nftStaking.updateRewardsDelayPeriod(2 * 24 * 60 * 60);
    expect(await nftStaking.rewardDelayPeriod()).to.equal(2 * 24 * 60 * 60);
  });
});