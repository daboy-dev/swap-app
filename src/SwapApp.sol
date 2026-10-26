// SPDX-License-Identifier: MIT

pragma solidity ^0.8.37;

import {IV2Router02} from "./IV2Router02.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SwapApp {
    using SafeERC20 for IERC20;

    address public V2Router02Address;
    
    event SwapTokens(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    constructor(address V2Router02Address_) {
        V2Router02Address = V2Router02Address_;
    }

    function swapTokens(uint256 amountIn, uint256 amountMinOut, address[] memory path, uint256 deadline) external {
        IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(path[0]).approve(V2Router02Address, amountIn);
        uint[] memory amounts = IV2Router02(V2Router02Address).swapExactTokensForTokens(amountIn, amountMinOut, path, msg.sender, deadline);

        emit SwapTokens(path[0], path[path.length - 1], amountIn, amounts[amounts.length - 1]);
    }
}