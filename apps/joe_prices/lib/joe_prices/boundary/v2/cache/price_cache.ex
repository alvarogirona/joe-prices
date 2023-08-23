defmodule JoePrices.Boundary.V2.Cache.PriceCache do
  @type network_name :: :arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet

  @moduledoc """
  Module for managin Cachex access for prices.
  """
  alias JoePrices.Boundary.V2.Cache.PriceCacheEntry
  alias JoePrices.Boundary.V2.PriceRequest
  alias JoePrices.Core.V21.Pair

  @spec get_price(network_name(), PriceRequest.t()) :: {:ok, term()}
  def get_price(network, request = %PriceRequest{}) do
    key = cache_key_for_tokens(request)
    table = get_table_name(network, request.version)

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

  @spec update_prices(network_name(), atom, [JoePrices.Core.V21.Pair.t()]) :: nil | {:error, boolean} | {:ok, boolean}
  def update_prices(_, _, []) do end
  def update_prices(network, version, [price]), do: update_price(network, version, price)
  def update_prices(network, version, [price | rest]) do
    update_price(network, version, price)
    update_prices(network, version, rest)
  end

  @spec update_price(atom, atom, Pair.t()) :: any
  defp update_price(network, version, pair = %Pair{}) do
    key = cache_key_for_tokens(pair)
    table = get_table_name(network, version)
    cache_entry = PriceCacheEntry.new(pair)

    Cachex.put(table, key, cache_entry)
  end

  @spec get_table_name(network_name(), atom) :: atom
  def get_table_name(:arbitrum_mainnet, :v21), do: :arbitrum_mainnet_prices_cache_v21
  def get_table_name(:avalanche_mainnet, :v21), do: :avalanche_mainnet_prices_cache_v21
  def get_table_name(:bsc_mainnet, :v21), do: :bsc_mainnet_prices_cache_v21

  def get_table_name(:arbitrum_mainnet, :v20), do: :arbitrum_mainnet_prices_cache_v20
  def get_table_name(:avalanche_mainnet, :v20), do: :avalanche_mainnet_prices_cache_v20
  def get_table_name(:bsc_mainnet, :v20), do: :bsc_mainnet_prices_cache_v20

  @spec cache_key_for_tokens(%{
          :bin_step => any,
          :token_x => any,
          :token_y => any,
          optional(any) => any
        }) :: nonempty_binary
  def cache_key_for_tokens(%{:token_x => tx, :token_y => ty, :bin_step => bin_step} = _tokens) do
    joined_tokens = [tx, ty]
      |> Enum.sort()
      |> Enum.join("-")

    joined_tokens <> "-" <> "#{bin_step}"
  end
end
