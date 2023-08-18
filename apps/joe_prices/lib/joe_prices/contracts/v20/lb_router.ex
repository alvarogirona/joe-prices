defmodule JoePrices.Contracts.V20.LbRouter do
  use Ethers.Contract,
    abi_file: "priv/abis/v20/LBRouter.json",
    default_address: "0xE3Ffc583dC176575eEA7FD9dF2A7c65F7E23f4C3"

  def contract_for_network(:avalanche_mainner), do: "0xE3Ffc583dC176575eEA7FD9dF2A7c65F7E23f4C3"
  def contract_for_network(:arbitrum_mainnet), do: "0x7BFd7192E76D950832c77BB412aaE841049D8D9B"
  def contract_for_network(:bsc), do: "0xb66A2704a0dabC1660941628BE987B4418f7a9E8"
end
