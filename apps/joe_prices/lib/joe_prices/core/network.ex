defmodule JoePrices.Core.Network do
  defstruct name: :name

  def get_rpc_from_network(:arbitrum_mainnet), do: "https://rpc.ankr.com/arbitrum"
  def get_rpc_from_network(:avalanche_mainnet), do: "https://rpc.ankr.com/avalanche"
  def get_rpc_from_network(:bsc_mainnet), do: "https://rpc.ankr.com/bsc"
end
