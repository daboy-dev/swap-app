# SwapApp

A minimal token swap contract built on top of the **Uniswap V2 Router02**, written in Solidity with [Foundry](https://book.getfoundry.sh/) and tested against a fork of **Arbitrum One**.

This is a learning project from the Blockchain Accelerator academy. The goal is not to compete with an aggregator but to show how to integrate an existing protocol safely and how to test that integration against real on-chain state.

## How it works

`SwapApp.swapTokens` swaps an exact amount of one ERC20 for another through the Uniswap V2 Router02:

1. Pulls `amountIn` of `path[0]` from the caller with `safeTransferFrom` (the caller must approve `SwapApp` first).
2. Approves the router to spend that amount.
3. Calls `swapExactTokensForTokens`, sending the output tokens **directly to the caller**.
4. Emits `SwapTokens(tokenIn, tokenOut, amountIn, amountOut)`.

```solidity
function swapTokens(
    uint256 amountIn,
    uint256 amountMinOut,
    address[] memory path,
    uint256 deadline
) external;
```

| Parameter      | Meaning                                                              |
| -------------- | -------------------------------------------------------------------- |
| `amountIn`     | Exact amount of `path[0]` to sell, in the token's smallest unit.     |
| `amountMinOut` | Minimum amount of the last token to accept. The swap reverts below it (slippage protection). |
| `path`         | Token route, e.g. `[USDT, DAI]`. Intermediate hops are allowed.      |
| `deadline`     | Unix timestamp after which the router rejects the swap.              |

The router address is passed to the constructor, so the same contract can be deployed on any chain where Uniswap V2 (or a compatible fork) exists.

### Design notes

- **Minimal interface.** `src/IV2Router02.sol` declares only the function the contract calls instead of importing the full Uniswap V2 periphery package. `swapExactTokensForTokens` is declared in `IUniswapV2Router01`, which Router02 inherits. The interface only has to match the deployed contract's signature.
- **`SafeERC20`.** Transfers go through OpenZeppelin's `SafeERC20`, which handles tokens that do not return a boolean (USDT being the classic example).
- **Output goes straight to the user.** The router sends the swapped tokens to `msg.sender`, so `SwapApp` never holds the output tokens.

## Getting started

### Requirements

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- An Arbitrum One RPC URL (a public one such as `https://arbitrum.drpc.org` works, though it can be rate limited)

### Install

```shell
git clone --recurse-submodules https://github.com/daboy-dev/swap-app
cd swap-app
forge build
```

If you cloned without `--recurse-submodules`, run `git submodule update --init --recursive`.

## Testing

The swap tests need real Uniswap pools and real token balances, so they run on a fork of Arbitrum One:

```shell
forge test --fork-url https://arbitrum.drpc.org
```

Useful variations:

```shell
# Full call traces
forge test --fork-url https://arbitrum.drpc.org -vvvv

# A single test
forge test --fork-url https://arbitrum.drpc.org --match-test test_RevertWhen_DeadlineExpired

# Pin the block: reproducible results, and the state is cached locally so it runs much faster
forge test --fork-url https://arbitrum.drpc.org --fork-block-number <block>
```

### What is covered

| Test                              | Checks                                                           |
| --------------------------------- | ---------------------------------------------------------------- |
| `test_HasBeenDeployedCorrectly`   | The router address is stored correctly in the constructor.       |
| `test_SwapTokens_EmitsEvent`      | A USDT → DAI swap on the forked chain succeeds and emits `SwapTokens`. |
| `test_RevertWhen_DeadlineExpired` | An expired deadline reverts with `UniswapV2Router: EXPIRED`.     |

### How to tell the fork is active

Forge prints nothing about the fork by default. A test only proves it when it touches state that exists on that chain, such as the router's code or a real token balance. You can also compare `block.chainid`: `42161` on the Arbitrum fork versus `31337` on Foundry's local chain. Running the swap test without `--fork-url` should fail.

## Addresses used (Arbitrum One)

| Contract              | Address                                      |
| --------------------- | -------------------------------------------- |
| Uniswap V2 Router02   | `0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24` |
| USDT (USD₮0)          | `0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9` |
| DAI                   | `0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1` |

## Project structure

```
src/
├── SwapApp.sol         # Swap contract
└── IV2Router02.sol     # Minimal Uniswap V2 Router02 interface
test/
└── SwappApp.t.sol      # Fork tests
```

## Disclaimer

Educational project. It has not been audited, so do not use it with real funds.

## License

MIT
