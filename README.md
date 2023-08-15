# JoePrices

## Configuring RPCs

A sample `.env.sample` file is included with the project. To configure different RPC endpoints the environment variables defined on that file can be changed.

`env.sample`:
```
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

```
mix deps.get
MIX_ENV=prod mix phx.server
```

## Available endpoints

```
GET  /api/v2_1/prices/:token_x/:token_y/:bin_step  JoePricesWeb.Api.V21.PriceController :index
```

## Generating a release

An specific release for you OS and architecture can be created by running:

```
WIP
```
