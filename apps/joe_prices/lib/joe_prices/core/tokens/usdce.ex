defmodule JoePrices.Core.Tokens.USDCe do
  @behaviour JoePrices.Core.Tokens.Stable

  def address_for_network(:arbitrum_mainnet), do: "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8"
  def address_for_network(_), do: ""
end
