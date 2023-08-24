defmodule JoePrices.Contracts.V20.LbPair do
  use Ethers.Contract,
    abi_file: "priv/abis/v20/LBPair.json"

  alias JoePrices.Core.Network

  @doc """
  Fetches active bin for a given pair.

  ## Parameters

  - `network` (chain): chain to make the request (i.e: `:avalanche_mainnet`)
  - `pair_address`: address of the pair

  ## Example

  ```
  iex> JoePrices.Contracts.V20.LbPair.fetch_active_bin(:avalanche_mainnet, "0x1d7a1a79e2b4ef88d2323f3845246d24a3c20f1d")
  ```
  """
  @spec fetch_active_bin_id(atom(), String.t()) :: {:error, any} | {:ok, any}
  def fetch_active_bin_id(network, pair_address) do
    opts = Network.opts_for_call(network, pair_address)

    case __MODULE__.get_reserves_and_id(opts) do
      {:ok, [_, _, active_bin_id]} -> {:ok, [active_bin_id]}
      _ -> {:error, :undefined_error}
    end
  end

  @doc """

  ## Example
  ```
  iex> JoePrices.Contracts.V20.LbPair.fetch_tokens(:avalanche_mainnet, "0xD446eb1660F766d533BeCeEf890Df7A69d26f7d1")
  [
    ["0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7"],
    ["0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e"]
  ]
  ```
  """
  @spec fetch_tokens(:arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet, binary) ::
          [String.t() | String.t()]
          | {:error, any}
  def fetch_tokens(network, contract_address) do
    opts = Network.opts_for_call(network, contract_address)

    with {:ok, [token_x]} <- __MODULE__.token_x(opts),
         {:ok, [token_y]} <- __MODULE__.token_y(opts) do
      [token_x, token_y]
    end
  end
end
