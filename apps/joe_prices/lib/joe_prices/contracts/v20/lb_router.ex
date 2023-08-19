defmodule JoePrices.Contracts.V20.LbRouter do
  use Ethers.Contract,
    abi_file: "priv/abis/v20/LBRouter.json",
    default_address: "0xE3Ffc583dC176575eEA7FD9dF2A7c65F7E23f4C3"


  alias JoePrices.Core.Network

  @doc """
  Fetches price for a given pair and bin_id

  ## Parameters

  - `network` (chain): chain to make the request (i.e: `:avalanche_mainnet`)
  - `pair_address`: address of the pair

  ## Example

  ```
  iex> JoePrices.Contracts.V20.LbRouter.fetch_price_for_bin(:avalanche_mainnet, "0x1d7a1a79e2b4ef88d2323f3845246d24a3c20f1d", 8388603)
  ```
  """
  def fetch_price_for_bin(network, pair_address, bin_id) do
    opts = Network.opts_for_call(network, contract_for_network(network))

    __MODULE__.get_price_from_id(pair_address, bin_id, opts)
  end

  defp contract_for_network(:avalanche_mainnet), do: "0xE3Ffc583dC176575eEA7FD9dF2A7c65F7E23f4C3"
  defp contract_for_network(:arbitrum_mainnet), do: "0x7BFd7192E76D950832c77BB412aaE841049D8D9B"
  defp contract_for_network(:bsc_mainnet), do: "0xb66A2704a0dabC1660941628BE987B4418f7a9E8"
end
