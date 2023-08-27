defmodule JoePrices.Boundary.V1.PriceCache.PriceCache do
  alias JoePrices.Boundary.V1.PriceRequest
  alias JoePrices.Contracts.V1.JoePair

  @type network_name :: :arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet

  @spec get_price(JoePrices.Boundary.V1.PriceRequest.t()) :: {atom, any}
  def get_price(%PriceRequest{:network => network} = request) do
    table_name = get_table_name(network)
    key = cache_key_for_tokens(request)

    Cachex.get(table_name, key)
  end

  @spec update_prices(network_name(), [JoePair.t()]) :: any()
  def update_prices(network, pairs) do
    Enum.each(pairs, fn price -> update_price(network, price) end)
  end

  @spec update_price(network_name(), JoePair.t()) :: {:error, boolean} | {:ok, boolean}
  def update_price(network, %JoePair{} = pair) do
    key = cache_key_for_tokens(pair)
    table = get_table_name(network)

    Cachex.put(table, key, pair)
  end

  @spec get_table_name(network_name()) :: atom
  def get_table_name(:arbitrum_mainnet), do: :arbitrum_mainnet_prices_cache_v1
  def get_table_name(:avalanche_mainnet), do: :avalanche_mainnet_prices_cache_v1
  def get_table_name(:bsc_mainnet), do: :bsc_mainnet_prices_cache_v1

  @spec cache_key_for_tokens(%{:__struct__ => JoePrices.Boundary.V1.PriceRequest | JoePrices.Contracts.V1.JoePair}) :: list
  def cache_key_for_tokens(%PriceRequest{base_asset: token_x, quote_asset: token_y}) do
    [token_x, token_y]
    |> Enum.sort()
  end

  def cache_key_for_tokens(%JoePair{} = pair) do
    [pair.token_x, pair.token_y]
    |> Enum.sort()
  end
end
