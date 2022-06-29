//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOracle {
    function getRate(
        IERC20 srcToken,
        IERC20 dstToken,
        bool useWrappers
    ) external view returns (uint256 weightedRate);
}
