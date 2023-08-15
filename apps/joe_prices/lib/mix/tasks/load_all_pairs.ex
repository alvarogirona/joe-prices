defmodule Mix.Tasks.LoadAllPairs do
  @moduledoc """
  Task to get all the available pairs for the LBFactory contract on a network.

  Accepted args:
    - avalanche_mainnet
    - arbitrum_mainnet
    - bsc_mainnet

  ## Example

    $ mix load_all_pairs avalanche_mainnet
  """

  use Mix.Task

  alias JoePrices.Core.Network
  alias JoePrices.Utils.Parallel

  @impl Mix.Task
  def run([network_arg] = _args) do
    Mix.Task.run("app.start")

    network = Network.network_from_string(network_arg)

    pairs = load_pairs(network)
  end

  @doc """
  ## Example
    iex> JoePrices.Boundary.V21.TokenPairsWorker.load_prices(:avalanche_mainnet)
  """
  def load_pairs(network) do
    pairs = JoePrices.Contracts.V21.LbFactory.fetch_pairs(network)

    pairs
    |> Enum.take(5)
    |> Parallel.pmap(fn pair ->
      [token_x, token_y] = JoePrices.Contracts.V21.LbPair.fetch_tokens(network, pair)

      token_x_name = fetch_token_name(network, token_x)
      token_y_name = fetch_token_name(network, token_y)

      {:ok, bin_step} = JoePrices.Contracts.V21.LbPair.fetch_bin_step(network, pair)

      %{
        :token_x => token_x,
        :token_y => token_y,
        :pair_name => "#{token_x_name}-#{token_y_name}",
        :bin_step => bin_step,
      }
    end)

  end

  def fetch_token_name(network, token_address) do
    opts = Network.opts_for_call(network, token_address)
    {:ok, [token_name]} = Ethers.Contracts.ERC20.name(opts)
    token_name
  end
end
