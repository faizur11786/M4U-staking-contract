//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import {Pool} from "./Pool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IPoolFactory {
    function getPoolInfo() external view returns (address[] memory);
}

contract PoolFactory is Ownable {
    address[] private pools;
    IERC20 public token;
    address public tokenPayer;

    address public referralManager;

    event PoolCreated(address pool, uint8 mROI, uint8 releaseSteps);
    event PoolRemoved(address pool);

    constructor(
        IERC20 _token,
        address _tokenPayer,
        address _referralManager
    ) Ownable() {
        token = _token;
        tokenPayer = _tokenPayer;
        referralManager = _referralManager;
    }

    function setToken(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    function setTokenPayer(address _tokenPayer) external onlyOwner {
        tokenPayer = _tokenPayer;
    }

    function setReferralManager(address _referralManager) external onlyOwner {
        referralManager = _referralManager;
    }

    function getPoolInfo() external view returns (address[] memory) {
        return pools;
    }

    function createPool(
        string memory _poolName,
        uint256 _poolTokenPrice,
        uint8 _mROI,
        uint8 _releaseSteps
    ) external onlyOwner returns (bool) {
        Pool newPool = new Pool(
            _poolName,
            _poolTokenPrice,
            _mROI,
            _releaseSteps,
            token,
            tokenPayer,
            referralManager,
            owner()
        );
        pools.push(address(newPool));
        emit PoolCreated(address(newPool), _mROI, _releaseSteps);
        return true;
    }

    function removePool(address _pool) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < pools.length; i++) {
            if (pools[i] == _pool) {
                pools[i] = pools[pools.length - 1];
            }
        }
        pools.pop();
        emit PoolRemoved(_pool);
        return true;
    }
}
