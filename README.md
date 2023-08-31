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

Pair processes are identified by the `PriceRequest` struct:
```elixir
  defstruct token_x: "",
            token_y: "",
            bin_step: 0,
            network: :avalanche_mainnet,
            version: :v21
```

The `PriceCache` modules handle interacting with the cache. Cachex is used as the underlying cache. At application start (`apps/joe_prices/lib/joe_prices/application.ex`) a cache process for each network and version is created.

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

### Finding the value in $

For pairs that do not have a stable coin in them, the `PriceComputator` module searches if there is any pair with one of the pair assets and a `primary_quote_asset`. 

Primary quote assets are defined at `JoePrices.Core.V2.Token` (`apps/joe_prices/lib/joe_prices/core/v21/token.ex`).

If there is a related pair with an stable then the price in dollars is retrieved from that pair.

If there is a related pair with a `primary_quote_asset` that is not an stable (i.e: Avax in Avalanche, WETH in arbitrum), then it searches for stable pairs for that asset and makes the required conversions between pairs to get the price.

### Info about created pairs

`JoePrices.Boundary.V2.PairInfoCache.PairsInfoFetcher` module serves as a cache for info about pairs (tokens, address, bin_step), which are used for finding the path to a stable coin and computing the price in $.

This module loads all the pairs info from a json file (from `apps/joe_prices/priv/pairs`) to speed up app start.

It also has methods for loading the price directly from the contracts. The json files come from the output of that method:
```elixir
@spec load_all_pairs(available_versions(), available_networks()) :: any()
def load_all_pairs(version, network) do
...
end
```

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

### Batch requests

The expected format for batch requests body is:
```json
{
	"tokens": [
		{
			"token_y": "0x49d5c2bdffac6ce2bfdb6640f4f80f226bc10bab",
			"token_x": "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e",
			"bin_step": 15
		},
		{
			"token_x": "0xd586e7f844cea2f87f50152665bcbc2c279d8d70",
			"token_y": "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e",
			"bin_step": 1
		},
		{
			"token_x": "0xc7198437980c041c805a1edcba50c1ce5db95118",
			"token_y": "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e",
			"bin_step": 1
		},
		{
			"token_x": "0x152b9d0fdc40c096757f570a51e494bd4b943e50",
			"token_y": "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e",
			"bin_step": 10
		},
		{
			"token_x": "0x5947bb275c521040051d82396192181b413227a3",
			"token_y": "0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7",
			"bin_step": 10
		},
		{
			"token_y": "0x152b9d0fdc40c096757f570a51e494bd4b943e50",
			"token_x": "0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7",
			"bin_step": 10
		}
	]
}
```

Response is in the following format:
```json
[
	{
		"price": 6.071798130750191e-4,
		"token_x": "0x49d5c2bdffac6ce2bfdb6640f4f80f226bc10bab",
		"token_y": "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e",
		"base_asset": "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e",
		"quote_asset": "0x49d5c2bdffac6ce2bfdb6640f4f80f226bc10bab"
	},
	{
		"price": 0.999203001599911,
		"token_x": "0xd586e7f844cea2f87f50152665bcbc2c279d8d70",
		"token_y": "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e",
		"base_asset": "0xd586e7f844cea2f87f50152665bcbc2c279d8d70",
		"quote_asset": "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e"
	},
	{
		"price": 0.9989006597141001,
		"token_x": "0xc7198437980c041c805a1edcba50c1ce5db95118",
		"token_y": "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e",
		"base_asset": "0xc7198437980c041c805a1edcba50c1ce5db95118",
		"quote_asset": "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e"
	},
	{
		"price": 26013.997545333943,
		"token_x": "0x152b9d0fdc40c096757f570a51e494bd4b943e50",
		"token_y": "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e",
		"base_asset": "0x152b9d0fdc40c096757f570a51e494bd4b943e50",
		"quote_asset": "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e"
	},
	{
		"price": -1,
		"token_x": "0x5947bb275c521040051d82396192181b413227a3",
		"token_y": "0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7",
		"base_asset": "0x5947bb275c521040051d82396192181b413227a3",
		"quote_asset": "0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7"
	},
	{
		"price": 3.8444613725162905e-4,
		"token_x": "0x152b9d0fdc40c096757f570a51e494bd4b943e50",
		"token_y": "0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7",
		"base_asset": "0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7",
		"quote_asset": "0x152b9d0fdc40c096757f570a51e494bd4b943e50"
	}
]
```

Here the response with price `-1` corresponds to a `LINK.e/AVAX` pair (`0xc0dfc065894b20d79aade34a63b5651061b135cc`) which does not have enough liquidity, so `-1` is returned.

The first and last requests have `token_x` and `token_y` inverted from the pair tokens, so the "inverse" price (1/price) is returned. `quote_asset` and `base_asset` come from the pair, while `token_x` and `token_y` values from the response are the ones from the request.

## Generating a release

An specific release for you OS and architecture can be created by running:

```bash
mix release #`MIX_ENV=prod mix release` for a production build
```

## Stress testing

Inside the `locust` directory there is a script to run a stress test agains the api.

It requires Python.

You can launch it by executing `locust` from that directory (a Python virtual environment for setting up the dependencies is recommended).

## Possible improvements

### Cache structure for PairsInfo

`JoePrices.Boundary.V2.PairInfoCache.PairsInfoFetcher` stores a cache of available pairs in a list. A "dictionary" (map) structure would improve the access and search for pairs, but its not a huge trade-off since the amount of pairs is "limited".

### PairsInfoFetcher pairs

`PairsInfoFetcher` has methods for loading all pairs directly from the contract, but uses a json dump of that method to load all tokens in app start and doesn't look for new pairs. 

An scheduled task could be checking for the number of available pairs at a given interval (`LbFactory.get_number_of_lb_pairs`) and load newly avaible pairs if they appear. 

I think this is a small limitation and focused on other parts, but it is not 100% correct how it is currently done, since a new pair could be created and it wouldn't be taken into account when checking the liquidity constraints (`PairsInfoFetcher` is mainly used for searching for paths from TOKEN_X/TOKEN_Y to a stable pair which allows to determine if there are >10$ in the bins around the active bin).

