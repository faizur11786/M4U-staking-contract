// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IPoolFactory} from "./interface/IPoolFactory.sol";

contract Referral is Ownable, ReentrancyGuard {
    uint8 private constant MAX_LEVEL = 3;
    uint256[(MAX_LEVEL)] private persentagePerLevel;

    IPoolFactory public poolFactory;
    IERC20 public token;
    address public tokenPayer;

    struct Account {
        address referee;
        uint256 amount;
        uint8 referredCount;
        uint256 claimableBonus;
    }

    event RegisteredRefererFailed(
        address indexed referrer,
        address indexed referee,
        string reason
    );
    event RegisteredReferer(
        address indexed referrer,
        address indexed referee,
        uint256 amount
    );
    event ClaimedBonus(address referee, uint256 amount, uint256 referredCount);

    constructor(
        uint256[] memory _persentagePerLevel,
        IERC20 _token,
        address _tokenPayer
    ) Ownable() ReentrancyGuard() {
        token = _token;
        tokenPayer = _tokenPayer;
        for (uint8 i = 0; i < MAX_LEVEL; i++) {
            persentagePerLevel[i] = _persentagePerLevel[i];
        }
    }

    function setPoolFactory(address _poolFactory) external onlyOwner {
        poolFactory = IPoolFactory(_poolFactory);
    }

    function setToken(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    function setTokenPayer(address _tokenPayer) external onlyOwner {
        tokenPayer = _tokenPayer;
    }

    // Create a mapping of address to ReferralInfo array
    mapping(address => Account) private accounts;

    // create function to get the referral info of a user
    function getAccounts(address _address)
        public
        view
        returns (Account memory)
    {
        return accounts[_address];
    }

    function addReferral(
        address _referrer,
        address _referee,
        uint256 _amount
    ) external returns (bool) {
        require(indexOf(_msgSender()), "Only Pools can add Referrals");
        Account storage userAccount = accounts[_referrer];
        if (_referee == userAccount.referee) {
            emit RegisteredRefererFailed(
                _referrer,
                _referee,
                "This user is already your referral or Referee is 0x0"
            );
            return false;
        }
        userAccount.amount = _amount;
        userAccount.referee = _referee;
        if (
            _referee != address(0) && !isCircularReference(_referee, _referrer)
        ) {
            setParaentsDataOf(_referrer, _amount);
        } else {
            emit RegisteredRefererFailed(
                _referrer,
                _referee,
                "Circular Reference"
            );
            return false;
        }
        return true;
    }

    function indexOf(address _address) internal view returns (bool) {
        address[] memory addresses = poolFactory.getPoolInfo();
        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function isCircularReference(address _referee, address _referrer)
        internal
        view
        returns (bool)
    {
        address parent = _referee;
        for (uint8 i = 0; i < MAX_LEVEL; i++) {
            if (parent == _referrer) {
                return true;
            }
            parent = accounts[parent].referee;
        }
        return false;
    }

    function setParaentsDataOf(address _address, uint256 _amount) internal {
        Account storage account = accounts[_address];
        for (uint8 i = 0; i < MAX_LEVEL; i++) {
            Account storage parents = accounts[account.referee];
            if (account.referee != address(0)) {
                parents.referredCount++;
                parents.claimableBonus +=
                    (((persentagePerLevel[i] * 1e18) / 100) * _amount) /
                    1e18;
                emit RegisteredReferer(
                    _address,
                    account.referee,
                    (((persentagePerLevel[i] * 1e18) / 100) * _amount) / 1e18
                );
            }
            account = parents;
        }
    }

    function claimBonus() external nonReentrant returns (bool) {
        Account storage account = accounts[_msgSender()];
        require(account.claimableBonus > 0, "No bonus to claim");
        token.transferFrom(tokenPayer, _msgSender(), account.claimableBonus);
        account.claimableBonus = 0;

        emit ClaimedBonus(
            _msgSender(),
            account.claimableBonus,
            account.referredCount
        );
        return true;
    }

    function withdrawFunds(IERC20 _token) external onlyOwner {
        require(_token.balanceOf(address(this)) > 0, "No funds to withdraw");
        _token.transfer(_msgSender(), _token.balanceOf(address(this)));
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }
}
