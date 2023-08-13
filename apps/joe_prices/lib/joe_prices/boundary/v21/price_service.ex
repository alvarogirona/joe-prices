defmodule JoePrices.Boundary.V21.TokenPairsWorker do

  alias JoePrices.Core.Network
  alias JoePrices.Utils.Parallel

  @doc """
  ## Example
    iex> JoePrices.Boundary.V21.TokenPairsWorker.load_prices(:avalanche_mainnet)
  """
  def load_prices(network) do
    pairs = JoePrices.Contracts.V21.LbFactory.fetch_pairs(network)

    pairs
    |> Enum.take(20)
    |> Parallel.pmap(fn pair ->
      [token_x, token_y] = JoePrices.Contracts.V21.LbPair.fetch_tokens(network, pair)

      token_x_name = fetch_token_name(network, token_x)
      token_y_name = fetch_token_name(network, token_y)

      {:ok, bin_step} = JoePrices.Contracts.V21.LbPair.fetch_bin_step(network, pair)
      {:ok, [active_bin]} = JoePrices.Contracts.V21.LbPair.fetch_active_bin_id(network, pair)

      %{
        :tokens => %{
          :token_x => token_x,
          :token_y => token_y
        },
        :pair_name => "#{token_x_name}-#{token_y_name}",
        :bin_step => bin_step,
        :active_bin => active_bin,
        :price => JoePrices.Core.V21.Bin.get_price_from_id(active_bin, bin_step),
        :updated_at => Time.utc_now
      }
    end)
  end

  def fetch_token_name(network, token_address) do
    opts = Network.opts_for_call(network, token_address)
    {:ok, [token_name]} = Ethers.Contracts.ERC20.name(opts)
    token_name
  end
end
