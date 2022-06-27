//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./Pool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PoolFactory is Ownable {
    address[] private pools;
    IERC20 public token;
    address public tokenPayer;

    constructor(IERC20 _token, address _tokenPayer) Ownable() {
        token = _token;
        tokenPayer = _tokenPayer;
    }

    function setToken(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    function setTokenPayer(address _tokenPayer) external onlyOwner {
        tokenPayer = _tokenPayer;
    }

    function getPoolInfo() public view returns (uint256, address[] memory) {
        return (pools.length, pools);
    }

    function createPool(string memory _poolName) public {
        // Pool newPool = new Pool();
        // // _poolName,
        // // 500000000000000000,
        // // block.timestamp,
        // // block.timestamp + 30 minutes
        // pools.push(address(newPool));
    }
}
