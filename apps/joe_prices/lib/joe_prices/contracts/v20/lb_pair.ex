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
  def fetch_active_bin(network, pair_address) do
    opts = Network.opts_for_call(network, pair_address)

    case __MODULE__.get_reserves_and_id(opts) do
      {:ok, [_, _, active_bin_id]} -> active_bin_id
      _ -> {:error, :undefined_error}
    end
  end
end
