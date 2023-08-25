defmodule JoePrices.Core.Tokens.USDT do
  @behaviour JoePrices.Core.Tokens.Stable

  def address_for_network(:avalanche_mainnet), do: "0x9702230a8ea53601f5cd2dc00fdbc13d4df4a8c7"
  def address_for_network(:arbitrum_mainnet), do: "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9"
  def address_for_network(:bsc_mainnet), do: "0x55d398326f99059ff775485246999027b3197955"
  def address_for_network(_), do: ""
end
