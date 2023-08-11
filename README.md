# A Playground for Uniswap v4 Hooks

## Examples

1. The example hook [Counter.sol](src/Counter.sol) demonstrates the `beforeSwap()` and `afterSwap()` hooks
2. The test template [Counter.t.sol](test/Counter.t.sol) preconfigures the v4 pool manager, test tokens, and test liquidity.

## Install

This project uses [Foundry](https://book.getfoundry.sh) to manage dependencies, compile contracts, test contracts and run a local node. See Foundry [installation](https://book.getfoundry.sh/getting-started/installation) for instructions on how to install Foundry which includes `forge` and `anvil`.

```
git clone git@github.com:naddison36/uniswap-v4-hooks.git
cd uniswap-v4-hooks
forge install
```

## Unit Testing

```
forge test
```

## Local Deployment

Because v4 exceeds the bytecode limit of Ethereum and it's _business licensed_, we can only deploy & test hooks on a local node like [Anvil](https://book.getfoundry.sh/anvil/).

The following runs the Foundry script [script/Counter.s.sol](./script/Counter.s.sol) against the local Anvil node that:

- deploys the Uniswap v4 PoolManager
- deploys [Counter](./src/Counter.sol) hook.
- adds the Counter hook to the PoolManager
- add liquidity to the pool
- does a swap

```bash
# start anvil, with a larger code limit
anvil --code-size-limit 30000
```

```bash
# in a new terminal
forge script script/Counter.s.sol \
    --rpc-url http://localhost:8545 \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --code-size-limit 30000 \
    --broadcast
```

## Uniswap v4 Feature Summary

- Lifecycle Hooks: initialize, position, swap and donate
- Hook managed fees
  - swap and/or withdraw
  - static or dynamic
- Swap and withdraw protocol fees
- ERC-1155 accounting of multiple tokens
- Native ETH pools like V1
- Donate liquidity to pools

## Contracts Diagrams

Contract dependencies

![Uniswap v4 Contract dependencies](./docs/uniswapContractsV4.png)

## Contribution

This repository was created from this GitHub project template https://github.com/saucepoint/v4-template

## Additional resources:

- [Uniswap v4 Core](https://github.com/Uniswap/v4-core/blob/main/whitepaper-v4-draft.pdf) whitepaper
- Uniswap [v4-core](https://github.com/uniswap/v4-core) repository
- Uniswap [v4-periphery](https://github.com/uniswap/v4-periphery) repository contains advanced hook implementations that serve as a great reference.
- A curated list of [Uniswap v4 hooks](https://github.com/fewwwww/awesome-uniswap-hooks#awesome-uniswap-v4-hooks)
