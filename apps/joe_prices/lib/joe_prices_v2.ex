defmodule JoePricesV2 do
  @moduledoc """
  This module provides functions to fetch and manage prices for token pairs on v2.0 and v2.1.

  It provides functions to get prices for a list of pairs (`get_prices/1`) and for a single pair (`get_price/1`).

  The prices are fetched from the `JoePrices.Boundary.V2.PairRepository` which caches them.
  """

  alias JoePrices.Boundary.V2.PriceRequest
  alias JoePrices.Boundary.V2.PriceCache.PriceCacheEntry
  alias JoePrices.Utils.Parallel

  @doc """
  Get prices for a given network and tokens.
  """
  @spec get_prices(list(PriceRequest.t())) :: [PriceCacheEntry.t()]
  def get_prices(pairs) do
    pairs
    |> Parallel.pmap(&get_price(&1))
  end

  @doc """
  Gets the price for a pair of tokens on v2.1 and bin step

  ## Example

  ```elixir
  iex> alias JoePrices.Boundary.V2.PriceRequest
  iex> request = %PriceRequest{token_x_address: "0x49d5c2bdffac6ce2bfdb6640f4f80f226bc10bab", token_y_address: "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e", bin_step: 15}
  iex> JoePricesV21.get_price(:avalanche_mainnet, request)
  ```
  """
  @spec get_price(PriceRequest.t()) :: {:ok, PriceCacheEntry.t()} | {:error, any()}
  def get_price(request = %PriceRequest{}) do
    JoePrices.Boundary.V2.PairRepository.get_price(request)
  end
end
