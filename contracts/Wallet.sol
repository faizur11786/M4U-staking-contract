//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOracle} from "./interface/IOracle.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

interface IPancakeRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}

contract Wallet is Ownable {
    address private constant PANCAKE_ROUTER =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private constant PANCAKE_FACTORY =
        0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address private constant BSC_ORACLE =
        0xfbD61B037C325b959c0F6A7e69D8f37770C2c550;
    address private constant M4U_TOKEN =
        0x564c4C6FA8994f3f4C1eE9e61193cc093cdb98Fe;

    address public foundReceiver; // This address will get 80% of the deposit amount;
    address public tokenPayer; // This address will get 10% of the deposit amount. also this is the addres how give the M4U token to add liquidity.

    event LiquidityAdded(
        uint256 amountA,
        uint256 amountB,
        address indexed from,
        uint256 timestamp
    );

    event Deposit(
        address indexed from,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity,
        uint256 tokenPayerTo,
        uint256 foundReceiverTo,
        uint256 rate,
        uint256 timestamp
    );

    constructor(address _foundReceiver, address _tokenPayer) Ownable() {
        foundReceiver = _foundReceiver;
        tokenPayer = _tokenPayer;
    }

    function setFoundReceiver(address _foundReceiver) public onlyOwner {
        foundReceiver = _foundReceiver;
    }

    function setTokenPayer(address _tokenPayer) public onlyOwner {
        tokenPayer = _tokenPayer;
    }

    // When ever user deposit some token in call addLiquidity function and add 10% of in M4U Liquidity pool
    // ||==============||=============||================================||
    // ||              ||             ||                                ||
    // || in liquidity ||  for Owner  ||           in Wallet            ||
    // ||              ||             ||                                ||
    // 0%-------------10%-------------10%------------------------------80%
    // Total          10%      +      10%              +               80% = 100%

    function deposit(
        address _from,
        address _token,
        uint256 _amount
    )
        public
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(_token != address(0), "Invalid token");
        require(_amount > 0, "Invalid amount");

        IERC20 tokenA = IERC20(_token);
        IERC20 tokenB = IERC20(M4U_TOKEN);

        uint256 aTokenForBPayer = (_amount * 10) / 100;
        uint256 aTokenForLiquidity = (_amount * 10) / 100;

        address fromAddress = _from;
        _transferInto(fromAddress, tokenA, _amount);

        uint256 rate = IOracle(BSC_ORACLE).getRate(tokenA, tokenB, true);
        uint256 bTokenForLiquidity = (aTokenForLiquidity * rate) / 1e18;
        _transferInto(fromAddress, tokenB, bTokenForLiquidity);

        uint256 toReceiver = _amount - (aTokenForBPayer + aTokenForLiquidity); // 80% of the amount
        tokenA.transfer(foundReceiver, toReceiver);

        tokenA.transfer(tokenPayer, aTokenForBPayer); // 10% of the amount

        tokenA.approve(PANCAKE_ROUTER, aTokenForLiquidity);
        tokenB.approve(PANCAKE_ROUTER, bTokenForLiquidity);

        (uint256 amountA, uint256 amountB, uint256 liquidity) = IPancakeRouter(
            PANCAKE_ROUTER
        ).addLiquidity(
                address(tokenA),
                M4U_TOKEN,
                aTokenForLiquidity,
                bTokenForLiquidity,
                0,
                0,
                tokenPayer,
                block.timestamp + 60
            );

        emit Deposit(
            fromAddress,
            address(tokenA),
            address(tokenB),
            amountA,
            amountB,
            liquidity,
            aTokenForBPayer,
            toReceiver,
            rate,
            block.timestamp
        );

        return (amountA, amountB, liquidity);
    }

    function _transferInto(
        address _from,
        IERC20 _token,
        uint256 _amount
    ) public returns (bool) {
        require(
            _token.transferFrom(_from, address(this), _amount),
            "Transfer failed"
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
