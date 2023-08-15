# JoePrices

## Configuring RPCs

A sample `.env.sample` file is included with the project. To configure different RPC endpoints the environment variables defined on that file can be changed.

`env.sample`:
```bash
export AVAX_RPC_URL=https://rpc.ankr.com/avalanche
export ARB_RPC_URL=https://rpc.ankr.com/arbitrum
export BSC_RPC_URL=https://rpc.ankr.com/bsc
```

## Configuring cache TTL

Cache TTL is set for all caches when they are created on application start. 

App start can be configured in `/apps/joe_prices/lib/joe_prices/application.ex` and the TTL is set as `@cache_ttl_seconds 5`.

## Requirements

Elixir and erlang have to be installed on your machine.

## Running

The application can run directly with the following commands.

``` bash
mix deps.get
MIX_ENV=prod mix phx.server
```

### Running in interactive REPL/"CLI" mode

The application can also be run using `iex` for an interactive shell which allows you to run any method from the project.

```bash
$ iex -S mix # Or "iex -S mix phx.server" to run with web server
```

Example inside iex:
```elixir
iex> JoePrices.Contracts.V21.LbFactory.fetch_pairs(:arbitrum_mainnet)
    [
        ok: ["0x500173f418137090dad96421811147b63b448a0f"],
        ok: ["0xdf34e7548af638cc37b8923ef1139ea98644735a"],
        ok: ["0xd8053763b1179bd412a5a5a42fa2d15851518cfb"],
        ...
    ]
```

## Available endpoints

``` bash
GET  /api/v2_1/prices/:token_x/:token_y/:bin_step  JoePricesWeb.Api.V21.PriceController :index
```

## Generating a release

An specific release for you OS and architecture can be created by running:

```
WIP
```
