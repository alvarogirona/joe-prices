defmodule JoePrices.Contracts.V1.JoeFactory do
  use Ethers.Contract,
    abi_file: "priv/abis/v1/factory.json",
    default_address: "0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10"

    @contract_address "0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10"

    alias JoePrices.Core.Network

    @doc """
    0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7

    0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e

    JoePrices.Contracts.V1.JoeFactory.fetch_pair("0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7", "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e")
    """
    @spec fetch_pair(String.t(), String.t(), atom()) :: {:ok, binary()} | {:error, any()}
    def fetch_pair(token_x, token_y, network \\ :avalanche_mainnet) do
      opts = Network.opts_for_call(network, "0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10")

      with {:ok, [pair]} <- __MODULE__.get_pair(token_x, token_y, opts) do
        {:ok, pair}
      end
    end
end