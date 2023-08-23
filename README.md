# A Playground for Uniswap v4 Hooks

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

## Install

This project uses [Foundry](https://book.getfoundry.sh) to manage dependencies, compile contracts, test contracts and run a local node. See Foundry [installation](https://book.getfoundry.sh/getting-started/installation) for instructions on how to install Foundry which includes `forge` and `anvil`.

```
git clone git@github.com:naddison36/uniswap-v4-hooks.git
cd uniswap-v4-hooks
forge install
```

## Unit Testing

The following will run the unit tests in [test/Counter.t](./test/Counter.t.sol)

```
forge test
```

## Counter Hook Example

1. The [CounterHook](src/CounterHook.sol) demonstrates the `beforeModifyPosition`, `afterModifyPosition`, `beforeSwap` and `afterSwap` hooks.
2. The [Counter.t](test/Counter.t.sol) test deploys the v4 pool manager, test tokens, counter hook and test routers. It then sets up a pool, adds token liquidity and performs a swap.
3. The [Counter.s](script/Counter.s.sol) script deploys to a local Anvil node and does a swap.

![CounterHook Contract](./docs/CounterHook.svg)

### Local Testing

Because v4 exceeds the bytecode limit of Ethereum and it's _business licensed_, we can only deploy & test hooks on a local node like [Anvil](https://book.getfoundry.sh/anvil/).

The following runs the [script/Counter.s](./script/Counter.s.sol) Forge script against a local Anvil node that:

- Deploys the Uniswap v4 PoolManager
- Deploys the [CounterFactory](./src/CounterFactory.sol) contract.
- Uses the `CounterFactory` to deploy a [CounterHook](./src/CounterHook.sol) contract with the correct address prefix.
- Creates a new pool with `CounterHook` as the hook.
- Adds token liquidity to the pool
- Performs a token swap

```bash
# start anvil with a larger code limit
anvil --code-size-limit 30000
```

```bash
# in a new terminal, run the Forge script
forge script script/Counter.s.sol \
    --rpc-url http://localhost:8545 \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --code-size-limit 30000 \
    --broadcast
```

WARNING The above private key for account 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 is only used for Foundry testing. Do not use this known account on mainnet.

```bash
# Get the counter values from the CounterHook
export COUNTER=0x3CD91b522f2a6CB67F378d7fBee767602d5140bB
cast call $COUNTER "beforeSwapCounter()(uint256)" --rpc-url http://localhost:8545
cast call $COUNTER "afterSwapCounter()(uint256)" --rpc-url http://localhost:8545
```

Summary of the modify position calls

![Counter Modify Summary](./docs/counterModifySummary.svg)

Summary of the swap calls

![Counter Swap Summary](./docs/counterSwapSummary.svg)

See [here](./docs/README.md#counter-hook) for more detailed transaction traces with call parameters and events.

## My Hook

1. The [MyHook](src/MyHook.sol) contract has empty `beforeInitialize`, `afterInitialize`, `beforeModifyPosition`, `afterModifyPosition`, `beforeSwap`, `afterSwap`, `beforeDonate` and `afterDonate` hooks that can be implemented.
2. The [MyHook.s](script/MyHook.s.sol) script deploys to a local Anvil node and does a swap.

```bash
# start anvil with a larger code limit
anvil --code-size-limit 30000
```

```bash
# in a new terminal, run the Forge script
forge script script/MyHook.s.sol \
    --rpc-url http://localhost:8545 \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --code-size-limit 30000 \
    --broadcast
```

## Dynamic Fee Hook

1. The [DynamicFeeHook](src/DynamicFeeHook.sol) contract has an empty `getFee` function that is used to set the fee for dynamic fee pools.
   It also has empty `beforeModifyPosition`, `afterModifyPosition`, `beforeSwap` and `afterSwap` hooks but they are not required for a dynamic fee hook. They can be removed if not needed.
2. The [DynamicFeeHook.s](script/DynamicFeeHook.s.sol) script deploys to a local Anvil node and does a swap. Note the fee in the PoolKey is set with the `DYNAMIC_FEE_FLAG`.

```Solidity
// Derive the key for the new pool
poolKey = PoolKey(
    Currency.wrap(address(token0)), Currency.wrap(address(token1)), FeeLibrary.DYNAMIC_FEE_FLAG, 60, hook
);
// Create the pool in the Uniswap Pool Manager
poolManager.initialize(poolKey, SQRT_RATIO_1_1);
```

![DynamicFeeHook Contract](./docs/DynamicFeeHook.svg)

Summary of the swap calls

![Dynamic Fee Swap Summary](./docs/dynamicFeeSwapSummary.svg)

### Local Testing

```bash
# start anvil with a larger code limit
anvil --code-size-limit 30000
```

The following runs the [DynamicFeeHook.s](script/DynamicFeeHook.s.sol) Forge script against a local Anvil node

```bash
# in a new terminal, run the Forge script
forge script script/DynamicFeeHook.s.sol \
    --rpc-url http://localhost:8545 \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --code-size-limit 30000 \
    --broadcast
```

## Contribution

This repository was created from this GitHub project template https://github.com/saucepoint/v4-template. Thanks [@saucepoint](https://twitter.com/saucepoint) for an excellent starting point. This repo has significantly evolved from the starting template.

## Additional resources:

- [Uniswap v4 Core](https://github.com/Uniswap/v4-core/blob/main/whitepaper-v4-draft.pdf) whitepaper
- Uniswap [v4-core](https://github.com/uniswap/v4-core) repository
- Uniswap [v4-periphery](https://github.com/uniswap/v4-periphery) repository contains advanced hook implementations that serve as a great reference.
- A curated list of [Uniswap v4 hooks](https://github.com/fewwwww/awesome-uniswap-hooks#awesome-uniswap-v4-hooks)
- [Uniswap v4 Hooks: Create a fully on-chain "take-profit" orders hook on Uniswap v4](https://learnweb3.io/lessons/uniswap-v4-hooks-create-a-fully-on-chain-take-profit-orders-hook-on-uniswap-v4/)
- [SharkTeam's Best Security Practices for UniswapV4 Hooks](https://twitter.com/sharkteamorg/status/1686673161650417664)
- [Research - What bad hooks look like](https://uniswap.notion.site/Research-What-bad-hooks-look-like-b10256c445904111914eb3b01fb4ec53)
