defmodule JoePrices.Contracts.V21.LbPair do
  alias JoePrices.Core.Network

  @type network_name() :: :arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet

  use Ethers.Contract,
    abi_file: "priv/abis/v21/LBPair.json",
    default_address: "0x2f1da4bafd5f2508ec2e2e425036063a374993b6"

  @doc """

  ## Example
    iex> JoePrices.Contracts.V21.LbPair.fetch_active_bin_id(:arbitrum_mainnet, "0x500173f418137090dad96421811147b63b448a0f")
    {:ok, [8112282]}
  """
  @spec fetch_active_bin_id(network_name, String) :: any
  def fetch_active_bin_id(network, pair_contract) do
    opts =
      Network.opts_for_network(network)
      |> Keyword.merge(to: pair_contract)

    JoePrices.Contracts.V21.LbPair.get_active_id(opts)
  end

  @doc """
  ## Example
    iex> JoePrices.Contracts.V21.LbPair.fetch_bin_step(:arbitrum_mainnet, "0x500173f418137090dad96421811147b63b448a0f")
    {:ok, 1}
  """
  @spec fetch_bin_step(network_name, String) ::
          non_neg_integer
          | {:error, any}
          | {:ok,
             <<_::528>>
             | [non_neg_integer]
             | %{data: binary, selector: ABI.FunctionSelector.t(), to: <<_::160, _::_*176>>}}
  def fetch_bin_step(network, contract_address) do
    opts =
      Network.opts_for_network(network)
      |> Keyword.merge(to: contract_address)

    case JoePrices.Contracts.V21.LbPair.get_bin_step(opts) do
      {:ok, [bin_step]} -> {:ok, bin_step}
      {:error, reason} -> {:error, reason}
      _ -> {:error}
    end
  end
end
