defmodule JoePrices.Core.Tokens.USDC do
  @behaviour JoePrices.Core.Tokens.Stable

  def address_for_network(:avalanche_mainnet), do: "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e"
  def address_for_network(:arbitrum_mainnet), do: "0xaf88d065e77c8cc2239327c5edb3a432268e5831"
  def address_for_network(:bsc_mainnet), do: "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d"
  def address_for_network(_), do: ""
end
