defmodule JoePrices.Core.Network do
  defstruct name: :name

  def get_rpc_from_network(:arbitrum_mainnet), do: "https://rpc.ankr.com/arbitrum/f93fa4bad7bb8f056d11b7e5b4de970adab31200521184e6a883476738a395ac"
  def get_rpc_from_network(:avalanche_mainnet), do: "https://rpc.ankr.com/avalanche/f93fa4bad7bb8f056d11b7e5b4de970adab31200521184e6a883476738a395ac"
  def get_rpc_from_network(:bsc_mainnet), do: "https://rpc.ankr.com/bsc/f93fa4bad7bb8f056d11b7e5b4de970adab31200521184e6a883476738a395ac"

  def network_from_string("avalanche_mainnet"), do: avalanche_mainnet()
  def network_from_string("arbitrum_mainnet"), do: arbitrum_mainnet()
  def network_from_string("bsc_mainnet"), do: bsc_mainnet()

  @spec arbitrum_mainnet :: :arbitrum_mainnet
  def arbitrum_mainnet(), do: :arbitrum_mainnet
  @spec avalanche_mainnet :: :avalanche_mainnet
  def avalanche_mainnet(), do: :avalanche_mainnet
  @spec bsc_mainnet :: :bsc_mainnnet
  def bsc_mainnet(), do: :bsc_mainnnet

  @spec all_networks :: [:arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnnet, ...]
  def all_networks(), do: [arbitrum_mainnet(), avalanche_mainnet(), bsc_mainnet()]

  @spec opts_for_call(:arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnnet, String) :: Keyword
  def opts_for_call(network, contract_address) do
    network_rpc = get_rpc_from_network(network)
    [rpc_opts: [rpc_opts: [url: network_rpc]], to: contract_address]
  end
end
