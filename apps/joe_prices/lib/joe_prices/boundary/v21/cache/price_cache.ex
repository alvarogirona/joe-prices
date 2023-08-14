defmodule JoePrices.Boundary.V21.Cache.PriceCache do
  @ttl 60
  @ets_table_suffix :prices_cache_v21

  @type network_name :: :arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet

  @moduledoc """
  Module for managin Cachex access for prices.
  """
  alias JoePrices.Boundary.V21.Cache.PriceCacheEntry
  alias JoePrices.Boundary.V21.PriceRequest

  def get_price(network, request) do
    key = cache_key_for_tokens(request)
    table = get_table_name(network)

    Cachex.get(table, key)
  end

  # TODO: batch implementation for updating cache
  # def update_prices(network, prices) do
  #   table = get_table_name(network)

  #   Cachex.execute!(table, fn cache ->
  #     Enum.each(prices, fn pair ->
  #       key = cache_key_for_tokens(pair)
  #       cache_entry = PriceCacheEntry.new(pair)
  #       Cachex.put(cache, key, cache_entry)
  #     end)
  #   end)
  # end

  def update_prices(network, []) do end
  def update_prices(network, [price]), do: update_price(network, price)
  def update_prices(network, [price | rest]) do
    update_price(network, price)
    update_prices(network, rest)
  end

  defp update_price(network, pair = %JoePrices.Core.V21.Pair{}) do
    key = cache_key_for_tokens(pair)
    table = get_table_name(network)
    cache_entry = PriceCacheEntry.new(pair)

    Cachex.put(table, key, cache_entry)
  end

  def get_table_name(network) when is_atom(network) do
    (Atom.to_string(network) <> Atom.to_string(@ets_table_suffix))
    |> String.to_atom
  end

  def cache_key_for_tokens(%{:token_x_address => tx, :token_y_address => ty, :bin_step => bin_step} = tokens) do
    joined_tokens = [tx, ty]
      |> Enum.sort()
      |> Enum.join("-")

    joined_tokens <> "-" <> "#{bin_step}"
  end
end
