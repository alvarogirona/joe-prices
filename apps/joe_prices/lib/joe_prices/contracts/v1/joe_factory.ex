defmodule JoePrices.Contracts.V1.JoeFactory do
  use Ethers.Contract,
    abi_file: "priv/abis/v1/factory.json",
    default_address: "0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10"

    @contract_address "0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10"

    alias JoePrices.Core.Network

    @doc """
    0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7

    0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e

    JoePrices.Contracts.V1.JoeFactory.get_pair("0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7", "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e")
    """

    def fetch_pair(token_x, token_y) do
      opts = Network.opts_for_call(:avalanche_mainnet, "0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10")
    end
end
