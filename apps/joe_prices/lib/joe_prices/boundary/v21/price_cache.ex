defmodule JoePrices.Boundary.V21.PriceCache do
  use GenServer

  import JoePrices.Utils.Parallel

  alias JoePrices.Contracts.V21.LbFactory, as: LBFactoryContract

  def init(opts) do
    {:ok, opts}
  end

  @spec start_link({:arb | :avax | :bsc, String}) :: {:ok, term}
  def start_link({network, address} = config) do
    GenServer.start_link(
      __MODULE__,
      {network, address},
      name: via(config),
    )
  end

  @doc """
    Returns all the available pairs from a cache.

    If the cache was expired, data is renewed before returning it.
  """
  def get_all_pairs({network, address} = name) do
    GenServer.call(via(name), {:get_all_pairs, name})
  end

  # GenServer Handlers
  def handle_call({:get_all_pairs, address} = name) do
    all_pairs = LBFactoryContract.get_all_pairs(name)
  end

  defp via({_network, _address} = name) do
    {
      :via,
      Registry,
      {JoePrices.Registry.V21.LBFactory, name},
    }
  end
end
