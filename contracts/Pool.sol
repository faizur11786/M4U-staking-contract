//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IOracle {
    function getRate(
        IERC20 srcToken,
        IERC20 dstToken,
        bool useWrappers
    ) external view returns (uint256 weightedRate);
}

contract MokeToken is ERC20 {
    constructor() ERC20("Blue BCT", "BBCT") {
        _mint(_msgSender(), 2500000000 * 1e18);
    }
}

contract Pool is Ownable, ReentrancyGuard {
    string public poolName;
    uint256 public poolTokenPrice;
    uint256 public poolStartTime;
    uint256 public poolEndTime;
    uint256 public releaseSteps;
    uint256 public totalRewardPercentage;
    bool public isListed = false;
    ERC20 public stakingToken;
    address public payer;

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

    constructor(address _payer, address _stakingToken)
        // string memory _poolName,
        // uint256 _poolTokenPrice,
        // uint256 _mROI,
        // uint256 _releaseSteps
        Ownable()
        ReentrancyGuard()
    {
        stakingToken = ERC20(_stakingToken);
        poolName = "_poolName";
        poolTokenPrice = 1000000000000000000; //_poolTokenPrice;
        poolStartTime = block.timestamp;
        poolEndTime = 12 * 5 seconds;
        // poolEndTime = 6 * 30 days;
        releaseSteps = 12;
        totalRewardPercentage = 50;
        payer = _payer;
        status = true;
    }

    modifier isActive() {
        require(status, "Pool is not active");
        _;
    }

    ///////////////////////////////////////////
    ///////////// Only For Owner //////////////
    ///////////////////////////////////////////

    function setStatus(bool _status) external onlyOwner {
        status = _status;
    }

    function setEndTime(uint256 _time) external onlyOwner {
        poolEndTime = block.timestamp + _time;
    }

    function setPrice(uint256 _price) external onlyOwner {
        poolTokenPrice = _price;
    }

    function setIsListed(bool _isListed) external onlyOwner {
        isListed = _isListed;
    }

    function withdrawFunds(IERC20 _token) external onlyOwner nonReentrant {
        require(_token.balanceOf(address(this)) > 0, "No funds to withdraw");
        _token.transfer(_msgSender(), _token.balanceOf(address(this)));
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    function stake(uint256 _amount, address _address)
        public
        isActive
        nonReentrant
        onlyOwner
        returns (bool)
    {
        require(_amount > 0, "Amount must be greater than 0");
        uint256 totalToken = (_amount * 1e18) / getTokenPrice();
        stakingToken.transferFrom(payer, address(this), totalToken);
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
        stakeInfo.endTime = block.timestamp + poolEndTime;
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
        if (isListed) {
            uint256 rate = IOracle(0x7F069df72b7A39bCE9806e3AfaF579E54D8CF2b9)
                .getRate(
                    stakingToken,
                    IERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063),
                    true
                );
            return rate;
        } else {
            return poolTokenPrice;
        }
    }

    ///////////////////////////////////////////
    //////////////// INTERNAL /////////////////
    ///////////////////////////////////////////

    function _percentePerSec() internal view returns (uint256) {
        return (totalRewardPercentage * 1e18) / poolEndTime;
    }

    function _nextRewardAt() internal view returns (uint256) {
        return block.timestamp + (poolEndTime / releaseSteps);
    }

    function _transfer(address _to, uint256 _value) internal {
        require(
            stakingToken.balanceOf(payer) >= _value,
            "Not enough tokens to transfer"
        );
        stakingToken.transferFrom(payer, _to, _value);
    }

    function _getClaimableRewards(address _staker)
        public
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

    function _stakingTimer(address _staker) public view returns (uint256) {
        if (!stakings[_staker].isStaked) {
            return 0;
        } else if (block.timestamp <= stakings[_staker].endTime) {
            return block.timestamp - stakings[_staker].rewardingAt;
        } else {
            return stakings[_staker].endTime - stakings[_staker].rewardingAt;
        }
    }

    ///////////////////////////////////////////
    ///////////////// PUBLIC //////////////////
    ///////////////////////////////////////////

    function claim() public nonReentrant returns (bool) {
        require(_isStake(_msgSender()), "Staking address is not staking");
        require(stakings[_msgSender()].isStaked, "Already unstaked");
        require(
            block.timestamp >= stakings[_msgSender()].nextRewardAt,
            "Reward not ready for claiming"
        );
        if (block.timestamp <= stakings[_msgSender()].endTime) {
            uint256 totalToken = claimableToken(_msgSender()) +
                stakings[_msgSender()].lastClaimableToken;
            _transfer(_msgSender(), totalToken);
            stakings[_msgSender()].rewardingAt = block.timestamp;
            stakings[_msgSender()].totalRewardClaimed += totalToken;
            stakings[_msgSender()].lastClaimableToken = 0;
            stakings[_msgSender()].nextRewardAt = _nextRewardAt();

            emit Claim(_msgSender(), totalToken, block.timestamp);
            return true;
        } else {
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
    }

    function claimableToken(address _staker) public view returns (uint256) {
        uint256 rewardsEarned = _getClaimableRewards(_staker);
        return ((((rewardsEarned * 1e18) / getTokenPrice()) * 1e18) / 1e18);
    }
}
