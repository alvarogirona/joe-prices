defmodule JoePrices.Contracts.V21.LbPair do

  alias JoePrices.Core.Network

  @type network_name() :: :arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet

  # 0x4b9bfeD1dD4E6780454b2B02213788f31FfBA74a
 use Ethers.Contract,
    abi_file: "priv/abis/v21/LBPair.json",
    default_address: "0x4b9bfeD1dD4E6780454b2B02213788f31FfBA74a"

    @doc """

    ## Example
      iex> JoePrices.Contracts.V21.LbPair.fetch_active_bin_id(:arbitrum_mainnet, "0x500173f418137090dad96421811147b63b448a0f")
      {:ok, [8112282]}
    """
    @spec fetch_active_bin_id(network_name, String) :: any
    def fetch_active_bin_id(network, pair_contract) do
      network_rpc = Network.get_rpc_from_network(network)

      JoePrices.Contracts.V21.LbPair.get_active_id(to: "0x500173f418137090dad96421811147b63b448a0f")
    end

    @doc """
    ## Example
      iex> JoePrices.Contracts.V21.LbPair.fetch_bin_step(:arbitrum_mainnet, "0x500173f418137090dad96421811147b63b448a0f")
      {:ok, [1]}
    """
    def fetch_bin_step(network, contract_address) do
      network_rpc = Network.get_rpc_from_network(network)

      with {:ok, [bin_step]} <- JoePrices.Contracts.V21.LbPair.get_bin_step(
        to: contract_address,
        rpc_opts: [{:url, network_rpc}]
      ) do
        bin_step
      end
    end
end
