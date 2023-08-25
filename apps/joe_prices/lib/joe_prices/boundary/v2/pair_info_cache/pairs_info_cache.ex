defmodule JoePrices.Boundary.V2.PairInfoCache.PairsInfoFetcher do
  @moduledoc """
  Loads and caches information about all available pairs for a version and network/chain.

  Ideally, when resolving if a given pair (TOKEN_A/TOKEN_B) with no stable assets has available liquidity,
  a path from TOKEN_A and TOKEN_B to a stable coin has to be resolved.

  This path can involve multiple jumps to different pairs (i.e: TOKEN_A/TOKEN_C -> TOKEN_C/USDC) in order
  to get the price of TOKEN_A quoted in USDC.

  Having a cache for all the available pairs of a version allows to quickly lookup for it.

  TODO: implement the path 
  """

  alias JoePrices.Utils.Parallel
  alias JoePrices.Core.Network
  alias JoePrices.Boundary.V2.PairInfoCache.PairCacheEntry

  @type available_versions() :: :v20 | :v21
  @type available_networks() :: :arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet

  def start_link(_args) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [[]]},
      type: :worker
    }
  end

  @doc """
  ## Example
      iex> JoePrices.Boundary.V2.PairInfoCache.PairsInfoFetcher.get_pairs(:v21, :avalanche_mainnet)
  """
  def get_pairs(version, network) do
    case Agent.get(__MODULE__, &Map.get(&1, {version, network})) do
      nil -> load_pairs_for_version(version, network)
      pairs -> pairs
    end
  end

  @spec load_all_pairs(available_versions(), available_networks()) :: any()
  def load_all_pairs(version, network) do
    load_pairs_for_version(version, network)
  end

  @doc """
  Loads all pairs.

  TODO: optimize fetch_token_name, could be cached.
  """
  defp load_pairs_for_version(:v21, network) do
    network
    |> JoePrices.Contracts.V21.LbFactory.fetch_pairs()
    |> Enum.take(10)
    |> Parallel.pmap(fn pair ->
      [token_x, token_y] = JoePrices.Contracts.V21.LbPair.fetch_tokens(network, pair)

      token_x_name = fetch_token_name(network, token_x)
      token_y_name = fetch_token_name(network, token_y)

      {:ok, bin_step} = JoePrices.Contracts.V21.LbPair.fetch_bin_step(network, pair)

      %PairCacheEntry{
        token_x: token_x,
        token_y: token_y,
        name: "#{token_x_name}-#{token_y_name}",
        pair_address: pair,
        bin_step: bin_step
      }
    end)
    |> save_to_cache(:v21, network)
  end

  defp save_to_cache(pairs, version, network) do
    Agent.update(__MODULE__, fn state ->
      Map.put(state, {version, network}, pairs)
    end)

    pairs
  end

  defp fetch_token_name(network, token_address) do
    opts = Network.opts_for_call(network, token_address)
    {:ok, [token_name]} = Ethers.Contracts.ERC20.name(opts)
    token_name
  end
end
