defmodule JoePrices.Boundary.V1.Cache.PriceCache do
  alias JoePrices.Boundary.V1.PriceRequest
  alias JoePrices.Contracts.V1.JoePair
  alias JoePrices.Boundary.V1.Cache.PriceCacheEntry

  @type network_name :: :arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet

  @spec get_price(PriceRequest.t(), network_name()) :: float()
  def get_price(%PriceRequest{:base_asset => base_asset, :quote_asset => quote_asset} = request, network) do
    table_name = get_table_name(network)
    key = cache_key_for_tokens(request)

    case Cachex.get(table_name, key) do
      {:ok, nil} -> {:ok, nil}
      {:ok, pair} ->
        if base_asset < quote_asset do
          pair.price
        else
          pair.inverse_price
        end
    end
  end

  @spec update_prices(network_name(), [JoePair.t()]) :: any()
  def update_prices(network, pairs) do
    Enum.each(pairs, fn price -> update_price(network, price) end)
  end

  @spec update_price(atom, JoePair.t()) :: any()
  def update_price(network, %JoePair{} = pair) do
    key = cache_key_for_tokens(pair)
    table = get_table_name(network)

    Cachex.put(table, key, pair)
  end

  @spec get_table_name(network_name()) :: atom
  def get_table_name(:arbitrum_mainnet), do: :arbitrum_mainnet_prices_cache_v1
  def get_table_name(:avalanche_mainnet), do: :avalanche_mainnet_prices_cache_v1
  def get_table_name(:bsc_mainnet), do: :bsc_mainnet_prices_cache_v1

  def cache_key_for_tokens(%PriceRequest{base_asset: token_x, quote_asset: token_y} = request) do
    [token_x, token_y]
    |> Enum.sort()
  end

  def cache_key_for_tokens(%JoePair{} = pair) do
    [pair.token_x, pair.token_y]
    |> Enum.sort()
  end
end
