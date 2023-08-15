defmodule JoePrices.Core.Network do
  @moduledoc """
  Module with helper methods for working with different chains/networks
  """

  defstruct name: :name

  @doc """
  Returns the rpc url for a network
  """
  @spec get_rpc_from_network(:arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet) :: String.t()
  def get_rpc_from_network(:arbitrum_mainnet),
    do:
      "https://rpc.ankr.com/arbitrum/f93fa4bad7bb8f056d11b7e5b4de970adab31200521184e6a883476738a395ac"

  def get_rpc_from_network(:avalanche_mainnet),
    do:
      "https://rpc.ankr.com/avalanche/f93fa4bad7bb8f056d11b7e5b4de970adab31200521184e6a883476738a395ac"

  def get_rpc_from_network(:bsc_mainnet),
    do:
      "https://rpc.ankr.com/bsc/f93fa4bad7bb8f056d11b7e5b4de970adab31200521184e6a883476738a395ac"

  @doc """
  Returns network atom from network string.
  """
  @spec network_from_string(String.t()) :: :arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnnet
  def network_from_string("avalanche_mainnet"), do: avalanche_mainnet()
  def network_from_string("arbitrum_mainnet"), do: arbitrum_mainnet()
  def network_from_string("bsc_mainnet"), do: bsc_mainnet()
  def network_from_string(_), do: raise("Undefined network")

  @spec arbitrum_mainnet :: :arbitrum_mainnet
  def arbitrum_mainnet(), do: :arbitrum_mainnet
  @spec avalanche_mainnet :: :avalanche_mainnet
  def avalanche_mainnet(), do: :avalanche_mainnet
  @spec bsc_mainnet :: :bsc_mainnnet
  def bsc_mainnet(), do: :bsc_mainnnet

  @doc """
  Returns a list with all the supported networks.
  """
  @spec all_networks :: [:arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnnet, ...]
  def all_networks(), do: [arbitrum_mainnet(), avalanche_mainnet(), bsc_mainnet()]

  @doc """
  Elixir Ethers library requires a series of parameters for calling an smart contract on different chains.

  This method helps building the options for making calls to a specific network and contract.

  Returns a keyword list like

  ```
  [rpc_opts: [rpc_opts: [url: network_rpc]], to: contract_address]
  ```

  Which can the be used to make a call to any contract

  ## Example

  ```elixir
  opts = Network.opts_for_call(:arbitrum_mainnet, "0x0000000...")
  LbPair.get_number_of_lb_pairs!(opts)
  ```
  """
  @spec opts_for_call(:arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet, String.t()) ::
          [{:rpc_opts, [{any, any}, ...]} | {:to, any}]
  def opts_for_call(network, contract_address) do
    network_rpc = get_rpc_from_network(network)
    [rpc_opts: [rpc_opts: [url: network_rpc]], to: contract_address]
  end
end
