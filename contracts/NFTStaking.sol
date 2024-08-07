// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "node_modules/@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "node_modules/@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

contract NFTStaking is ReentrancyGuardUpgradeable, UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    using SafeERC20 for IERC20;

    //ERC20 and ERC721 contracts that will be deployed and accessed here
    IERC20 public rewardTokens;
    IERC721 public nftCollection;

    uint256 private rewardsPerBlock;
    uint256 public unbondingPeriod;
    uint256 public rewardDelayPeriod;

    struct StakedToken {
        address staker;
        uint256 tokenId;
    }

    struct Staker {
        uint256 amountStaked;
        StakedToken[] stakedTokens;
        uint256 lastUpdateTime;
        uint256 unclaimedRewards;
        uint256 rewardClaimTime;
        uint256 lastBlockNumber;
    }

    mapping(address => Staker) public stakers;
    mapping(uint256 => address) public stakerAddress;
    mapping(uint256 => uint256) public unbondingStartTimes;

    function intialize (IERC20 _rewardTokens, IERC721 _nftCollection, address initialOwner) public {
        rewardTokens = _rewardTokens;
        nftCollection = _nftCollection;
        rewardsPerBlock = 100;
        unbondingPeriod = 3 days;
        rewardDelayPeriod = 1 days;
        __Ownable_init(initialOwner);
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    //overrides _authorizeUpgrade from the UUPS contract allowing user to upgrade this contract
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function stake(uint256 _tokenId) public nonReentrant whenNotPaused {
        if(stakers[msg.sender].amountStaked > 0) {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
        }

        require(nftCollection.ownerOf(_tokenId) == msg.sender, "You do not own this NFT");

        nftCollection.transferFrom(msg.sender, address(this), _tokenId);

        StakedToken memory stakedToken = StakedToken(msg.sender, _tokenId);
        stakers[msg.sender].stakedTokens.push(stakedToken);
        stakers[msg.sender].amountStaked++;
        stakerAddress[_tokenId] = msg.sender;
        stakers[msg.sender].lastUpdateTime = block.timestamp;
        stakers[msg.sender].lastBlockNumber = block.number;
    }

    function unstake(uint256 _tokenId) external nonReentrant whenNotPaused {
        require(stakers[msg.sender].amountStaked > 0, "You have no tokens staked");
        require(stakerAddress[_tokenId] == msg.sender, "You don't own this token!");

        uint256 index = 0;
        for(uint256 i = 0; i < stakers[msg.sender].stakedTokens.length; i++) {
            if(stakers[msg.sender].stakedTokens[i].tokenId == _tokenId) {
                index = i;
                break;
            }
        }

        stakers[msg.sender].stakedTokens[index].staker = address(0);
        stakers[msg.sender].amountStaked--;
        stakerAddress[_tokenId] = address(0);
        unbondingStartTimes[_tokenId] = block.timestamp;
        stakers[msg.sender].lastUpdateTime = block.timestamp;
        stakers[msg.sender].lastBlockNumber = block.number;
    }

    function withdraw(uint256 _tokenId) external nonReentrant whenNotPaused {
        require(block.timestamp >= unbondingStartTimes[_tokenId] + unbondingPeriod, "Please wait till the unbonding period is over!");
        require(stakerAddress[_tokenId] == msg.sender, "You don't own this token!");

        nftCollection.transferFrom(address(this), msg.sender, _tokenId);
    }

    function claimRewards() external whenNotPaused {
        require(block.timestamp >= stakers[msg.sender].rewardClaimTime + rewardDelayPeriod, "Please wait till the delay period is over to collect your rewards!");

        uint256 rewards = calculateRewards(msg.sender) + stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");

        stakers[msg.sender].lastUpdateTime = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;
        stakers[msg.sender].rewardClaimTime = block.timestamp;
        stakers[msg.sender].lastBlockNumber = block.number;

        rewardTokens.safeTransfer(msg.sender, rewards);
    }

    function calculateRewards(address _staker) internal view returns (uint256 _rewards) {
        return((block.number - stakers[_staker].lastBlockNumber) * (stakers[_staker].amountStaked * rewardsPerBlock));
    }

    function availableRewards(address _staker) public view returns (uint256) {
        uint256 rewards = calculateRewards(_staker) + stakers[_staker].unclaimedRewards;
        return rewards;
    }

    function getStakedTokens(address _user) public view returns (StakedToken[] memory) {
        if(stakers[_user].amountStaked > 0) {
            StakedToken[] memory _stakedTokens = new StakedToken[](stakers[_user].amountStaked);
            uint256 _index = 0;

            for(uint256 j = 0; j < stakers[_user].stakedTokens.length; j++) {
                if(stakers[_user].stakedTokens[j].staker != (address(0))) {
                    _stakedTokens[_index] = stakers[_user].stakedTokens[j];
                    _index++;
                }
            }

            return _stakedTokens;
        }

        else {
            return new StakedToken[](0);
        }
    }

    //functions to pause and unpause functions of this contract

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    //functions to update staking configurations

    function updateRewardsPerBlock(uint256 _newRewardsPerBlock) external onlyOwner {
        rewardsPerBlock = _newRewardsPerBlock;
    }

    function updateUnbondingPeriod(uint256 _newUnbondingPeriod) external onlyOwner {
        unbondingPeriod = _newUnbondingPeriod;
    }

    function updateRewardsDelayPeriod(uint256 _newRewardsDelayPeriod) external onlyOwner {
        rewardDelayPeriod = _newRewardsDelayPeriod;
    }
}