// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Referral is Ownable, ReentrancyGuard {
    uint8 private constant MAX_LEVEL = 3;
    uint256[(MAX_LEVEL)] private persentagePerLevel;

    IERC20 public token;
    address public tokenPayer;

    struct Account {
        address referee;
        uint256 amount;
        uint8 referredCount;
        uint256 claimableBonus;
    }

    event RegisteredRefererFailed(
        address referrer,
        address referee,
        string reason
    );

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

    // function diposit(uint256 _amount, address referee) public {
    //     addReferral(_msgSender(), referee, _amount);
    // }

    function addReferral(
        address _referrer,
        address _referee,
        uint256 _amount
    ) external returns (bool) {
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
            }
            account = parents;
        }
    }

    function claimBonus(address _address) external nonReentrant returns (bool) {
        Account storage account = accounts[_address];
        require(account.claimableBonus > 0, "No bonus to claim");
        token.transferFrom(tokenPayer, _address, account.claimableBonus);
        account.claimableBonus = 0;
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
