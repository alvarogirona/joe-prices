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
  """
  def fetch_pairs(network) do
    network_rpc = Network.get_rpc_from_network(network)
    contract_address = contract_for_network(network)

    [pairs_count] = __MODULE__.get_number_of_lb_pairs!(to: contract_address, rpc_opts: [{:url, network_rpc}])

    responses = 0..pairs_count
    |> Enum.to_list
    |> pmap(&__MODULE__.get_lb_pair_at_index(&1))

    ok_responses = responses
      |> Enum.filter(&match?({:ok, _}, &1))
  end

  defp contract_for_network(_), do: "0x8e42f2F4101563bF679975178e880FD87d3eFd4e"
end