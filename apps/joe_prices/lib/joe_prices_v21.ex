defmodule JoePricesV21 do
  alias JoePrices.Core.Network
  alias JoePrices.Boundary.V21.Cache.PriceCache
  alias JoePrices.Boundary.V21.PriceRequest
  alias JoePrices.Boundary.V21.Cache.PriceCacheEntry
  alias JoePrices.Core.V21.Pair
  alias JoePrices.Utils.Parallel

  @doc """
  Get prices for a given network and tokens.
  """
  @spec get_prices(list(PriceRequest.t())) :: [PriceCacheEntry.t()]
  def get_prices(pairs) do
    pairs
    |> Parallel.pmap(&get_price(&1))
    |> Enum.filter(&match?({:ok, _}, &1))
    |> Enum.map(fn {:ok, info} -> info end)
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
  @spec get_price(PriceRequest.t()) :: PriceCacheEntry.t()
  def get_price(request = %PriceRequest{}) do
    JoePrices.Boundary.V21.PairRepository.get_price(request)
  end
end
