//SPDX-License-Inentifier: Unlicense

pragma solidity ^0.8.0;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MokeToken is ERC20 {
    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        _mint(_msgSender(), 2500000000 * 1e18);
    }
}

contract DropBonus is Ownable {
    address public tokenPayer;
    IERC20 public token;
    uint256 public totalDropBonus;

    address[] private bonusReceivers;

    mapping(address => uint256) private bonusAmountOf;

    constructor(address _tokenPayer, IERC20 _tokne) Ownable() {
        tokenPayer = _tokenPayer;
        token = _tokne;
    }

    function _addBonusReceiver(address _receiver) internal {
        bonusReceivers.push(_receiver);
    }

    function getBonusReceivers()
        public
        view
        onlyOwner
        returns (address[] memory)
    {
        return bonusReceivers;
    }

    function setTokenPayer(address _tokenPayer) public onlyOwner {
        tokenPayer = _tokenPayer;
    }

    function setToken(IERC20 _token) public onlyOwner {
        token = _token;
    }

    function sandBonus(address _receiver, uint256 _amount)
        external
        onlyOwner
        returns (bool)
    {
        require(bonusAmountOf[_receiver] == 0, "Already received bonus");
        _addBonusReceiver(_receiver);
        token.transferFrom(tokenPayer, _receiver, _amount);
        totalDropBonus += _amount;
        bonusAmountOf[_receiver] = _amount;
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
