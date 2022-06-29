//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IPoolFactory {
    function getPoolInfo() external view returns (address[] memory);
}
