defmodule JoePrices.Contracts.V21.LbFactory do
  alias JoePrices.Utils.Parallel
  import Parallel

  alias JoePrices.Core.Network

  @type network_name() :: :arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet

  @doc """
  ## Example

    iex> JoePrices.Contracts.V21.LbFactory.fetch_pairs(:arbitrum_mainnet)
    [
      ok: ["0x500173f418137090dad96421811147b63b448a0f"],
      ok: ["0xdf34e7548af638cc37b8923ef1139ea98644735a"],
      ok: ["0xd8053763b1179bd412a5a5a42fa2d15851518cfb"],
      ...
    ]
  """
  use Ethers.Contract,
    abi_file: "priv/abis/v21/LBFactory.json",
    default_address: "0x8e42f2F4101563bF679975178e880FD87d3eFd4e"

  @doc """
  Calls contract to fetch all available pairs.

  ## Example
    iex> JoePrices.Contracts.V21.LbFactory.fetch_pairs(:avalanche_mainnet)
  """
  def fetch_pairs(network) do
    opts = Network.opts_for_call(network, contract_for_network(network))

    [pairs_count] = __MODULE__.get_number_of_lb_pairs!(opts)

    responses = 0..pairs_count - 1
      |> Enum.to_list
      |> pmap(&__MODULE__.get_lb_pair_at_index(&1, opts))

    responses
      |> Enum.filter(&match?({:ok, _}, &1))
      |> Enum.map(fn {:ok, [result]} -> result end)
  end

  @spec fetch_pairs_for_tokens(atom(), String.t(), String.t(), integer()) :: any
  def fetch_pairs_for_tokens(network, token_x, token_y, bin_step) do
    opts = Network.opts_for_call(network, contract_for_network(network))

    case JoePrices.Contracts.V21.LbFactory.get_lb_pair_information(token_x, token_y, bin_step, opts) do
      {:ok, pairs} -> {:ok, pairs}
      {:error, _} -> {:error, "Error getting pairs for tokens"}
    end
  end

  defp contract_for_network(_), do: "0x8e42f2F4101563bF679975178e880FD87d3eFd4e"
end
