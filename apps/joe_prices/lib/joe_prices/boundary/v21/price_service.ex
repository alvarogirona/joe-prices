defmodule JoePrices.Boundary.V21.PriceService do
  alias JoePrices.Utils.Parallel
  alias JoePrices.Boundary.V21.Cache.PriceCacheEntry
  alias JoePrices.Boundary.V21.Cache.PriceCache

  def get_prices(network, pairs) when is_list(pairs) do
    pairs
      |> Enum.map(fn pair -> get_price(network, pair) end)
  end

  @doc """
  ## Example
    iex> JoePrices.Boundary.V21.PriceService.load_prices(:avalanche_mainnet)
  """
  def get_price(network, price = %JoePrices.Boundary.V21.PriceRequest{}) do

  end
end
