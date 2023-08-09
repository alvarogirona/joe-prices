defmodule JoePrices.Core.Network do
  defstruct name: :name

  def get_rpc_from_network(:arbitrum_mainnet), do: "https://rpc.ankr.com/arbitrum"
  def get_rpc_from_network(:avalanche_mainnet), do: "https://api.avax.network/ext/bc/C/rpc"
  def get_rpc_from_network(:bsc_mainnet), do: "https://rpc.ankr.com/bsc"

  @spec arbitrum_mainnet :: :arbitrum_mainnet
  def arbitrum_mainnet(), do: :arbitrum_mainnet
  @spec avalanche_mainnet :: :avalanche_mainnet
  def avalanche_mainnet(), do: :avalanche_mainnet
  @spec bsc_mainnet :: :bsc_mainnnet
  def bsc_mainnet(), do: :bsc_mainnnet

  @spec all_networks :: [:arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnnet, ...]
  def all_networks(), do: [arbitrum_mainnet(), avalanche_mainnet(), bsc_mainnet()]
end
