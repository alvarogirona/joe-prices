defmodule JoePrices.Boundary.V21.PriceCache do
  use GenServer

  @ttl 60
  @ets_table_suffix :prices_cache_v21

  @type network_name :: :arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet

  @moduledoc """
  Cache for prices.

  ## Structure of the cache
  ```
    %{
      :updated_at => TIMESTAMP
      :items => {:key => CACHE_ITEM}
    }
  ```

  Key format:
  ```
  token_x_address-token_y_address
  ```
  * Sorted alphabetically

  `CACHE_ITEM`:
  ```
    %{
      token_x_address: String,
      token_y_address: String,
      active_bin: Int,
      bin_step: Int,
    }
  ```
  """

  import JoePrices.Utils.Parallel

  alias JoePrices.Contracts.V21.LbFactory, as: LBFactoryContract

  def child_spec([network: network] = opts) do
    %{
      id: network,
      start: {__MODULE__, :start_link, opts},
      shutdown: 30_000,
      restart: :permanent,
      type: :worker
    }
  end

  def init({network}) do
    create_ets_table(network)

    {:ok, {network}}
  end

  # @spec start_link({@network_name}) :: {:ok, term}
  def start_link({:network, network}) do
    IO.inspect(network)
    GenServer.start_link(
      __MODULE__,
      {network},
      name: via(network)
    )
  end

  @doc """
    Returns all the available pairs from a cache.

    If the cache was expired, data is renewed before returning it.

    ## Example

    iex> JoePrices.Boundary.V21.PriceCache.get_price(:arbitrum_mainnet, {1,2})
  """
  def get_price(network, {_token_x, _token_y} = tokens) do
    GenServer.call(via(network), {:get_all_pairs, tokens})
  end

  # GenServer Handlers
  def handle_call({:get_all_pairs, {token_x, token_y}}, _from, {network}) do
    IO.puts(">>>>> :get_all_pairs")
    # all_pairs = LBFactoryContract.fetch_pairs(network)
    # IO.inspect(all_pairs)

    table_name = get_table_name(network)
    IO.inspect(table_name)

    :ets.insert(table_name, {1, 2})

    {:reply, 1, {network}}
  end

  def lookup(network) do
    table_name = get_table_name(network)

    :ets.lookup(table_name, 1)
  end

  @doc """
  Function to be scheduled when the cache is refreshed to refresh it in the future.

  It will take a key and invalidate its contents.
  """
  def handle_info({:invalidate, key}, state) do
    :ets.delete(@ets_table, key)
    {:noreply, state}
  end

  defp create_ets_table(network) when is_atom(network) do
    table_name = get_table_name(network)
    :ets.new(table_name, [:set, :protected, :named_table])
  end

  defp get_table_name(network) when is_atom(network) do
    (Atom.to_string(network) <> Atom.to_string(@ets_table_suffix))
    |> String.to_atom
  end

  defp via(network) do
    {
      :via,
      Registry,
      {JoePrices.Registry.V21.PriceCache, network},
    }
  end
end
