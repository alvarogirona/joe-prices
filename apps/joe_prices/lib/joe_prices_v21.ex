defmodule JoePricesV21 do
  alias JoePrices.Core.Network
  alias JoePrices.Boundary.V21.Cache.PriceCache
  alias JoePrices.Boundary.V21.PriceRequest
  alias JoePrices.Boundary.V21.Cache.PriceCacheEntry
  alias JoePrices.Core.V21.Pair
  alias JoePrices.Utils.Parallel

  @moduledoc """
  Fecade for interacting with v2.1 pairs
  """

  @default_network Network.avalanche_mainnet()
  @bad_resp_addr "0x0000000000000000000000000000000000000000"

  @doc """
  Get prices for the default network.
  """
  @spec get_prices([PriceRequest.t()]) :: [PriceCacheEntry.t()]
  def get_prices(pairs) do
    get_prices(@default_network, pairs)
  end

  @doc """
  Get prices for a given network and tokens.
  """
  @spec get_prices(atom, list(PriceRequest.t())) :: any
  def get_prices(network, pairs) do
    pairs
    |> Parallel.pmap(fn request ->
      get_price(network, request)
    end)
    |> Enum.filter(&match?({:ok, _}, &1))
    |> Enum.map(fn {:ok, info} -> info end)
  end

  @doc """
  Gets the price for a single pair and the default network.

  ## Params
  - `network`: `:avalanche_mainnet` | `:arbitrum_mainnet` | `:bsc_mainnnet`
  """
  @spec get_price(PriceRequest.t()) :: PriceCacheEntry.t()
  def get_price(request = %PriceRequest{}) do
    __MODULE__.get_price(@default_network, request)
  end

  @doc """
  Gets the price for a pair of tokens on v2.1 and bin step

  ## Example

  ```elixir
  iex> alias JoePrices.Boundary.V21.PriceRequest
  iex> request = %PriceRequest{token_x_address: "0x49d5c2bdffac6ce2bfdb6640f4f80f226bc10bab", token_y_address: "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e", bin_step: 15}
  iex> JoePricesV21.get_price(:avalanche_mainnet, request)
  ```
  """
  @spec get_price(atom(), PriceRequest.t()) :: PriceCacheEntry.t()
  def get_price(network, request = %PriceRequest{}) do
    JoePrices.Boundary.V21.Cache.PriceCache.get_price(network, request)
    |> maybe_update_cache?(request, @default_network)
  end

  defp maybe_update_cache?({:ok, nil} = _resp, request = %PriceRequest{}, network) do
    %{:token_x => tx, :token_y => ty, :bin_step => bin_step} = request

    case JoePrices.Contracts.V21.LbFactory.fetch_pairs_for_tokens(network, tx, ty, bin_step) do
      {:ok, pairs} ->
        [info] = fetch_pairs_info(pairs, network: network)
        PriceCache.update_prices(network, [info])
        {:ok, info}
      _ ->
        {:error, "LBFactory contract call error (fetch_pairs_for_tokens)"}
    end
  end

  defp maybe_update_cache?({:ok, value} = _resp, _request, _network) do
    value
  end

  defp fetch_pairs_info(pairs, network: network) do
    pairs
    |> Enum.map(fn pair ->
      case pair do
        {_, @bad_resp_addr, _, _} ->
          nil

        {_, addr, _, _} ->
          [token_x, token_y] = JoePrices.Contracts.V21.LbPair.fetch_tokens(network, addr)

          {:ok, bin_step} = JoePrices.Contracts.V21.LbPair.fetch_bin_step(network, addr)
          {:ok, [active_bin]} = JoePrices.Contracts.V21.LbPair.fetch_active_bin_id(network, addr)

          %Pair{
            name: "",
            token_x: token_x,
            token_y: token_y,
            bin_step: bin_step,
            active_bin: active_bin
          }
      end
    end)
  end
end
