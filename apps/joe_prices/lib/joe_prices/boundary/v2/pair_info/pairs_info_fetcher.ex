defmodule JoePrices.Boundary.V2.PairInfoCache.PairsInfoFetcher do
  @moduledoc """
  Loads and caches information about all available pairs for a version and network/chain.

  Ideally, when resolving if a given pair (TOKEN_A/TOKEN_B) with no stable assets has available liquidity,
  a path from TOKEN_A and TOKEN_B to a stable coin has to be resolved.

  This path can involve multiple jumps to different pairs (i.e: TOKEN_A/TOKEN_C -> TOKEN_C/USDC) in order
  to get the price of TOKEN_A quoted in USDC.

  Having a cache for all the available pairs of a version allows to quickly lookup for it.

  TODO: Implement the path finding. *Currently Joe v2 limits the base assets that people can use to create
  pairs, so we can asume just 1 hop between pairs to get the USDC value.
  """

  alias JoePrices.Core.V2.Pair
  alias JoePrices.Utils.Parallel
  alias JoePrices.Core.Network
  alias JoePrices.Boundary.V2.PairInfoCache.PairCacheEntry
  alias JoePrices.Core.Tokens.Stable

  @type available_versions() :: :v20 | :v21
  @type available_networks() :: :arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet

  def start_link(_args) do
    agent = Agent.start_link(fn -> %{} end, name: __MODULE__)
    load_pairs_from_files()

    agent
  end

  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [[]]},
      type: :worker
    }
  end

  @doc """
  Returns a list of pairs containing the given token and some stable coin asset for the given version and network, sorted by bin step.

  ## Parameters:

  - token: address of the token to search for a pair with stable coins
  - version: version of liquidity book (`:v20` or `:v21`)
  - network: chain to check on

  ## Example

    iex> JoePrices.Boundary.V2.PairInfoCache.PairsInfoFetcher.find_stable_pairs_with_token("0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7", :v21, :avalanche_mainnet)
  """
  def find_stable_pairs_with_token(token, version, network) do
    get_pairs(version, network)
    |> Enum.filter(fn entry ->
      (String.downcase(entry.token_x) == String.downcase(token) or
         String.downcase(entry.token_y) == String.downcase(token)) and
        pair_has_stable(entry.token_x, entry.token_y, network)
    end)
    |> Enum.sort_by(fn pair -> pair.bin_step end)
  end

  defp pair_has_stable(token_x, token_y, network) do
    Stable.is_token_stable(token_x, network) or Stable.is_token_stable(token_y, network)
  end

  @spec find_pairs_with_token_and_primary_quote_asset(String.t(), available_versions(), available_networks()) :: list
  def find_pairs_with_token_and_primary_quote_asset(token, version, network) do
    get_pairs(version, network)
    |> Enum.filter(fn %PairCacheEntry{} = entry ->
      downcased_tx = String.downcase(entry.token_x)
      downcased_ty = String.downcase(entry.token_y)
      downcased_t = String.downcase(token)

      pair_contains_token =
        {downcased_tx, downcased_ty} == {downcased_t, downcased_ty} or
          {downcased_tx, downcased_ty} == {downcased_tx, downcased_t}

      pair_has_primary_quote =
        Token.is_primary_quote_asset?(downcased_tx, network) or
          Token.is_primary_quote_asset?(downcased_ty, network)

      pair_contains_token && pair_has_primary_quote
    end)
  end

  @doc """
  ## Example
      iex> JoePrices.Boundary.V2.PairInfoCache.PairsInfoFetcher.get_pairs(:v21, :avalanche_mainnet)
  """
  @spec get_pairs(available_versions(), available_networks()) :: any
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

  @spec load_pairs_from_json(available_versions(), available_networks()) :: :ok
  def load_pairs_from_json(version, network) do
    pairs_json_file(network, version)
    |> File.read!()
    |> Jason.decode!()
    |> Enum.map(&PairCacheEntry.new/1)
    |> save_to_cache(version, network)
  end

  defp pairs_json_file(:avalanche_mainnet, :v21), do: Path.join([:code.priv_dir(:joe_prices), "pairs/avalanche_v21_pairs.json"])
  defp pairs_json_file(:arbitrum_mainnet, :v21), do: Path.join([:code.priv_dir(:joe_prices), "pairs/arbitrum_v21_pairs.json"])
  defp pairs_json_file(:bsc_mainnet, :v21), do: Path.join([:code.priv_dir(:joe_prices), "pairs/bsc_v21_pairs.json"])

  # TODO: optimize fetch_token_name, could be cached.
  defp load_pairs_for_version(:v21, network) do
    network
    |> JoePrices.Contracts.V21.LbFactory.fetch_pairs()
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

  defp load_pairs_for_version(:v20, network) do
    network
    |> JoePrices.Contracts.V20.LbFactory.fetch_pairs()
    |> Parallel.pmap(fn pair ->
      [token_x, token_y] = JoePrices.Contracts.V20.LbPair.fetch_tokens(network, pair)

      token_x_name = fetch_token_name(network, token_x)
      token_y_name = fetch_token_name(network, token_y)

      {:ok, bin_step} = JoePrices.Contracts.V20.LbPair.fetch_bin_step(network, pair)

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

  defp load_pairs_from_files() do
    versions = [:v21]
    networks = JoePrices.Core.Network.all_networks()

    for v <- versions, nw <- networks do
      # JoePrices.Boundary.V2.PairInfoCache.PairsInfoFetcher.load_all_pairs(v, nw)
      JoePrices.Boundary.V2.PairInfoCache.PairsInfoFetcher.load_pairs_from_json(v, nw)
    end
  end
end
