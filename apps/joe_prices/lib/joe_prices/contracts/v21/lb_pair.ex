defmodule JoePrices.Contracts.V21.LbPair do
  alias JoePrices.Core.Network

  @type network_name() :: :arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet

  use Ethers.Contract,
    abi_file: "priv/abis/v21/LBPair.json",
    default_address: "0x2f1da4bafd5f2508ec2e2e425036063a374993b6"

  @doc """

  ## Example
    iex> JoePrices.Contracts.V21.LbPair.fetch_active_bin_id(:avalanche_mainnet, "0x2f1da4bafd5f2508ec2e2e425036063a374993b6")
    {:ok, [8112282]}
  """
  @spec fetch_active_bin_id(network_name, String) :: any
  def fetch_active_bin_id(network, pair_contract) do
    opts = Network.opts_for_call(network, pair_contract)

    JoePrices.Contracts.V21.LbPair.get_active_id(opts)
  end

  @doc """
  ## Example
    iex> JoePrices.Contracts.V21.LbPair.fetch_bin_step(:avalanche_mainnet, "0x2f1da4bafd5f2508ec2e2e425036063a374993b6")
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
    opts = Network.opts_for_call(network, contract_address)

    case JoePrices.Contracts.V21.LbPair.get_bin_step(opts) do
      {:ok, [bin_step]} -> {:ok, bin_step}
      {:error, reason} -> {:error, reason}
      _ -> {:error}
    end
  end

  @doc """
  ## Example

    iex> JoePrices.Contracts.V21.LbPair.fetch_tokens(:avalanche_mainnet, "0xD446eb1660F766d533BeCeEf890Df7A69d26f7d1")
    [
      ["0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7"],
      ["0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e"]
    ]
  """
  def fetch_tokens(network, contract_address) do
    opts = Network.opts_for_call(network, contract_address)

    with {:ok, [token_x]} <- JoePrices.Contracts.V21.LbPair.get_token_x(opts),
     {:ok, [token_y]} <- JoePrices.Contracts.V21.LbPair.get_token_y(opts) do
      [token_x, token_y]
    end
  end
end
