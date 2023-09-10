# Generic Router for Uniswap v4

- [UniswapV4Router](./UniswapV4Router.sol) a Uniswap v4 router that takes an array of generic calls that will be executed after getting a lock from the Uniswap PoolManager. The calls can be to the `PoolManager`, eg `modifyPosition`, `swap` , `settle`, `take`, `mint`, `safeTransfer` or `safeTransferFrom`. Or they can be to any other contract, eg a token transfer. The calls can optionally be delegated. They can also include the results of all the calls executed so far so callbacks can get `BalanceDelta` data from earlier `swap` or `modifyPosition` calls.

- [UniswapV4RouterLibrary](./UniswapV4RouterLibrary.sol) a library of Uniswap v4 operations. eg `addLiquidity` to a pool, `removingLiquidity` from a pool, `swap` tokens using a pool, `deposit` tokens to the pool manager, `withdraw` tokens from the pool manager or process a flash loan.

See the [docs README](../../docs/README.md) for example transactions that use the `UniswapV4Router`.

![UniswapV4Router Contract](../../docs/UniswapV4RouterLibrary.svg)

```
sol2uml class ../src,../lib -b UniswapV4Router
```
