// SPDX-License-Identifier: MIT

pragma solidity ^0.8.37;

import {Test} from "forge-std/Test.sol";
import {SwapApp} from "../src/SwapApp.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwappAppTest is Test {
    SwapApp swapApp;
    address uniswapV2SwappRouterAddress = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    address user = 0x050158426e9Ac6bc73E24D0b786c03516FA2D2f2; // Address with balance in Arbitrum Mainnet
    address USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9; // USDT address in Arbitrum Mainnet
    address DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1; // DAI address in Arbitrum Mainnet

    function setUp() public {
        swapApp = new SwapApp(uniswapV2SwappRouterAddress);
    }

    function test_HasBeenDeployedCorrectly() public view {
        assertEq(swapApp.V2Router02Address(), uniswapV2SwappRouterAddress);
    }

    function test_SwapTokens_EmitsEvent() public {
        vm.startPrank(user);

        uint256 amountIn = 2 * 1e6;
        uint256 amountOutMin = 1 * 1e18;
        uint256 deadline = block.timestamp + 5 minutes;
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = DAI;
        uint256 usdtBefore = IERC20(USDT).balanceOf(user);
        uint256 daiBefore = IERC20(DAI).balanceOf(user);

        IERC20(USDT).approve(address(swapApp), amountIn);

        assertEq(IERC20(USDT).balanceOf(user), usdtBefore - amountIn);
        assertGe(IERC20(DAI).balanceOf(user), daiBefore + amountOutMin);

        vm.expectEmit(false, false, false, false);
        emit SwapApp.SwapTokens(USDT, DAI, amountIn, 0);
        swapApp.swapTokens(amountIn, amountOutMin, path, deadline);

        vm.stopPrank();
    }

    function test_RevertWhen_DeadlineExpired() public {
        vm.startPrank(user);

        uint256 amountIn = 2 * 1e6;
        uint256 amountOutMin = 1 * 1e18;
        uint256 deadline = block.timestamp - 1 minutes;
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = DAI;

        IERC20(USDT).approve(address(swapApp), amountIn);

        vm.expectRevert("UniswapV2Router: EXPIRED");
        swapApp.swapTokens(amountIn, amountOutMin, path, deadline);

        vm.stopPrank();
    }
}
