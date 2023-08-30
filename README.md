# JoePrices

## Configuring RPCs

A sample `.env.sample` file is included with the project. To configure different RPC endpoints the environment variables defined on that file can be changed.

`env.sample`:
```bash
export AVAX_RPC_URL=https://rpc.ankr.com/avalanche
export ARB_RPC_URL=https://rpc.ankr.com/arbitrum
export BSC_RPC_URL=https://rpc.ankr.com/bsc
```

### Default chain

The project supports Avalanche, BSC and Arbitrum chains, but Avalanche is set as the default network.

The `PriceRequest` struct located at `apps/joe_prices/lib/joe_prices/boundary/v1/price_request.ex` and `apps/joe_prices/lib/joe_prices/boundary/v2/price_request.ex` have `:avalanche_mainnet` as their default value.

The API endpoints could be easily changed to have the chain as a parameter and then it could be added when `PriceRequest` are constructed at the controllers in `apps/joe_prices_web/lib/joe_prices_web/controllers/api`

## Configuring cache TTL

Cache TTL is set for all caches when they are created on application start. 

App start can be configured in `./apps/joe_prices/lib/joe_prices/application.ex` and the TTL is set as `@cache_ttl_seconds 2`.

## How pairs are cached

An Elixir process is created for pair by the `JoePrices.Boundary.V2.PairRepository` module when the `get_price` method is called if no previous process for that pair exist, if it exist the existing process is fetched:

```elixir
@spec get_price(PriceRequest.t()) :: JoePair.t()
def get_price(%PriceRequest{} = request) do
    with {:ok, pid} <- fetch_process(request) do
        GenServer.call(pid, {:fetch_price, request})
    end
end
```

Having a process for each price serializes multiple requests to the same pair, so if many requests are made at the same time only the first one will call the RPC, while the rest will wait for the first request to finish and then will hit the cache.

## Parallelising batch requests

Batch requests are parallelised by the `pmap` method located in the `JoePrices.Util.Parallel` module (`apps/joe_prices/lib/joe_prices/utils/parallel.ex`)

```elixir
@spec get_prices(list(PriceRequest.t())) :: list({:ok, Pair.t()} | {:error, any()})
def get_prices(pairs) do
    pairs
    |> Parallel.pmap(&get_price(&1))
end
```

## Checking for available liqudity

The contract modules (`apps/joe_prices/lib/joe_prices/contracts`) for LbPair in `v2` and `v21` have a method for checking if a pair has enought liquidity named `pair_has_enough_reserves_around_active_bin?`.

A pair has enough liquidity if in its +- bins around active bin there are more than 10$ of value. This value is defined by the value of `@minimum_liquidity_threshold` at the `LbPair` contract modules, which defaults to `10`.

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
  POST  /v1/batch-prices                          JoePricesWeb.Api.V1.PriceController :batch
  GET   /v1/prices/:base_asset/:quote_asset       JoePricesWeb.Api.V1.PriceController :index
  POST  /v2/batch-prices                          JoePricesWeb.Api.V20.PriceController :batch
  GET   /v2/prices/:token_x/:token_y/:bin_step    JoePricesWeb.Api.V20.PriceController :index
  POST  /v2_1/batch-prices                        JoePricesWeb.Api.V21.PriceController :batch
  GET   /v2_1/prices/:token_x/:token_y/:bin_step  JoePricesWeb.Api.V21.PriceController :index
```

## Generating a release

An specific release for you OS and architecture can be created by running:

```bash
mix release #`MIX_ENV=prod mix release` for a production build
```
