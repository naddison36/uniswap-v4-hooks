# Example Uniswap v4 Transactions

## Counter Hook

### CounterHook Contract

![CounterHook Contract](./CounterHook.svg)

```
sol2uml class ../src,../lib -b CounterHook
```

<!-- ### Pool Setup

[Counter Swap](./counterSwap.svg)

```
tx2uml --nodeType anvil --configFile counter.config.json -t -l -g -v 0x9cf249890694687e28f66952c3a0469e9150dc788c2a4983ba7e373433270c44,0xc1756dfb5669fe320edb26f99150f836448b07aed75b453604fe3af20ba97e72,0x02ff4b04a82193eba7247358a09a1d0630159a0e54d946d1d45a10dff6ce3388 -o counterSetup
``` -->

### Add Liquidity

![Counter Add Summary](./counterAddSummary.svg)

```
tx2uml --nodeType anvil --configFile counter.config.json -p -l -g -t -v 0x801443fb37b2b6a6acb7a3c1a7d0d0744c237f2bb69defe06319d1ac286d6fe2 -o counterAddSummary
```

![Counter Add Detailed](./counterAddDetailed.svg)

```
tx2uml --nodeType anvil --configFile counter.config.json -g -t -v 0x801443fb37b2b6a6acb7a3c1a7d0d0744c237f2bb69defe06319d1ac286d6fe2 -o counterAddDetailed
```

### Swap

![Counter Swap Summary](./counterSwapSummary.svg)

```
tx2uml --nodeType anvil --configFile counter.config.json -p -l -g -t -v 0xdf85e1e3bc524858d3fdf7288efc8d5f5cdb68ea442d5e3c5a3c562c04a20a57 -o counterSwapSummary
```

![Counter Swap Detailed](./counterSwapDetailed.svg)

```
tx2uml --nodeType anvil --configFile counter.config.json -g -t -v 0xdf85e1e3bc524858d3fdf7288efc8d5f5cdb68ea442d5e3c5a3c562c04a20a57 -o counterSwapDetailed
```
