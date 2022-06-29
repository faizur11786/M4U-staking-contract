//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IReferral {
    function addReferral(
        address,
        address,
        uint256
    ) external returns (bool);
}
