//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {PoolFactory} from "./PoolFactory.sol";
import {Referral} from "./Referral.sol";
import {IOracle} from "./interface/IOracle.sol";
import {IReferral} from "./interface/IReferral.sol";

contract Pool is Ownable, ReentrancyGuard {
    string public poolName;
    uint256 public poolStartTime;
    uint256 public poolLockedTime;
    uint256 public releaseSteps;
    uint256 public totalRewardPercentage;
    bool public isUnStakeable = false;
    IERC20 public token;
    address public tokenPayer;
    IReferral public referralManager;

    bool public status;

    uint256 public totalStaked;
    
    // structyou for holding staking information
    struct StakingInfo {
        uint256 amount;
        uint256 rewardingAt;
        uint256 startTime;
        uint256 endTime;
        uint256 totalRewardClaimed;
        uint256 lastClaimableToken;
        uint256 nextRewardAt;
        bool isStaked;
        uint256 index;
    }
    // Mapping of staking address to Array of staking information
    mapping(address => StakingInfo) private stakings;

    // events
    event Stake(
        address staker,
        uint256 amount,
        uint256 usdValue,
        uint256 timeStamp
    );
    event UnStake(
        address staker,
        uint256 amount,
        uint256 usdValue,
        uint256 timeStamp
    );
    event Claim(address staker, uint256 reward, uint256 timeStamp);

    constructor(
        string memory _poolName,
        uint256 _mROI,
        uint256 _releaseStepsInDays,
        IERC20 _token,
        address _tokenPayer,
        address _referralManager,
        address _owner,
        bool _isUnStakeable
    ) Ownable() ReentrancyGuard() {
        token = IERC20(_token);
        poolName = _poolName;
        releaseSteps = _releaseStepsInDays * 1 days / 30 days;
        totalRewardPercentage = _mROI * _releaseStepsInDays * 1 days / 30 days;
        tokenPayer = _tokenPayer;
        referralManager = IReferral(_referralManager);
        poolStartTime = block.timestamp;
        poolLockedTime = _releaseStepsInDays * 1 days;
        status = true;
        transferOwnership(_owner);
        isUnStakeable = _isUnStakeable;
    }

    modifier isActive() {
        require(status, "Pool is not active");
        _;
    }

    ///////////////////////////////////////////
    ///////////// Only For Owner //////////////
    ///////////////////////////////////////////

    function setIsUnStakeable(bool _isUnStakeable) external onlyOwner {
        isUnStakeable = _isUnStakeable;
    }

    function setStatus(bool _status) external onlyOwner {
        status = _status;
    }

    function setReferralManager(address _referralManager) external onlyOwner {
        referralManager = IReferral(_referralManager);
    }

    function setEndTime(uint256 _time) external onlyOwner {
        poolLockedTime = block.timestamp + _time;
    }

   


    function withdrawFunds(IERC20 _token) external onlyOwner {
        require(_token.balanceOf(address(this)) > 0, "No funds to withdraw");
        _token.transfer(_msgSender(), _token.balanceOf(address(this)));
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    function stake(
        uint256 _amount,
        address _address,
        address _referrer
    ) public isActive onlyOwner returns (bool) {
        require(_amount > 0, "Amount must be greater than 0");
        uint256 totalToken = (_amount * 1e18) / getTokenPrice();
        token.transferFrom(tokenPayer, address(this), totalToken);
        referralManager.addReferral(_address, _referrer, _amount);
        StakingInfo storage stakeInfo = stakings[_address];

        if (_isStake(_address)) {
            stakeInfo.lastClaimableToken += claimableToken(_address);
            stakeInfo.amount += _amount;
        } else {
            stakeInfo.amount = _amount;
            stakeInfo.startTime = block.timestamp;
            stakeInfo.lastClaimableToken = 0;
        }
        stakeInfo.rewardingAt = block.timestamp;
        stakeInfo.endTime = block.timestamp + poolLockedTime;
        stakeInfo.nextRewardAt = _nextRewardAt();
        stakeInfo.isStaked = true;
        stakeInfo.index++;
        totalStaked += totalToken;
        emit Stake(_msgSender(), totalToken, _amount, block.timestamp);
        return true;
    }

    ///////////////////////////////////////////
    //////////////// Read Only ////////////////
    ///////////////////////////////////////////

    function getStakeInfo(address _staker)
        external
        view
        returns (StakingInfo memory)
    {
        return stakings[_staker];
    }

    function getTokenPrice() public view returns (uint256) {
       uint256 rate = IOracle(0xfbD61B037C325b959c0F6A7e69D8f37770C2c550)
                .getRate(
                    token,
                    IERC20(0x55d398326f99059fF775485246999027B3197955),
                    true
                );
            return rate;
    }

    ///////////////////////////////////////////
    //////////////// INTERNAL /////////////////
    ///////////////////////////////////////////

    function _percentePerSec() internal view returns (uint256) {
        return (totalRewardPercentage * 1e18) / poolLockedTime;
    }

    function _nextRewardAt() internal view returns (uint256) {
        return block.timestamp + (poolLockedTime / releaseSteps);
    }

    function _transfer(address _to, uint256 _value) internal {
        require(
            token.balanceOf(tokenPayer) >= _value,
            "Not enough tokens to transfer"
        );
        token.transferFrom(tokenPayer, _to, _value);
    }

    function _getClaimableRewards(address _staker)
        internal
        view
        returns (uint256)
    {
        return
            (((_percentePerSec() * _stakingTimer(_staker)) / 100) *
                (stakings[_staker].amount)) / 1e18;
    }

    function _isStake(address _staker) internal view returns (bool) {
        return stakings[_staker].isStaked;
    }

    function _stakingTimer(address _staker) internal view returns (uint256) {
        if (!stakings[_staker].isStaked) {
            return 0;
        } else {
            return block.timestamp - stakings[_staker].rewardingAt;
        }
    }

    ///////////////////////////////////////////
    ///////////////// PUBLIC //////////////////
    ///////////////////////////////////////////

    function claim() public nonReentrant returns (bool) {
        require(_isStake(_msgSender()), "You are not staked");
        require(stakings[_msgSender()].isStaked, "Already unstaked");
        uint256 totalToken = claimableToken(_msgSender()) +
            stakings[_msgSender()].lastClaimableToken;
        _transfer(_msgSender(), totalToken);
        stakings[_msgSender()].rewardingAt = block.timestamp;
        stakings[_msgSender()].totalRewardClaimed += totalToken;
        stakings[_msgSender()].lastClaimableToken = 0;
        stakings[_msgSender()].nextRewardAt = _nextRewardAt();

        emit Claim(_msgSender(), totalToken, block.timestamp);
        return true;
    }

    function unStake() public nonReentrant returns (bool) {
        require(isUnStakeable, "Pool is not unstakeable");
        require(_isStake(_msgSender()), "Staking address is not staking");
        require(stakings[_msgSender()].isStaked, "Already unstaked");
        require(
            stakings[_msgSender()].endTime < block.timestamp,
            "Your funds are not yet unlocked"
        );
        uint256 totalToken = ((((stakings[_msgSender()].amount * 1e18) /
            getTokenPrice()) * 1e18) / 1e18) +
            claimableToken(_msgSender()) +
            stakings[_msgSender()].lastClaimableToken;
        totalStaked -= ((((stakings[_msgSender()].amount * 1e18) /
            getTokenPrice()) * 1e18) / 1e18);
        _transfer(_msgSender(), totalToken);
        stakings[_msgSender()].totalRewardClaimed += totalToken;
        stakings[_msgSender()].lastClaimableToken = 0;
        stakings[_msgSender()].isStaked = false;

        emit UnStake(
            _msgSender(),
            totalToken,
            ((totalToken * 1e18) / (getTokenPrice() * 1e18) / 1e18),
            block.timestamp
        );
        return true;
    }

    function isLocked(address _address) public view returns (bool) {
        return block.timestamp < stakings[_address].endTime;
    }

    function claimableToken(address _staker) public view returns (uint256) {
        uint256 rewardsEarned = _getClaimableRewards(_staker);
        return ((((rewardsEarned * 1e18) / getTokenPrice()) * 1e18) / 1e18);
    }
}
