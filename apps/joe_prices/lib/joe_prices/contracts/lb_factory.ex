defmodule JoePrices.Contracts.V21.LbFactory do
  alias JoePrices.Utils.Parallel
  import Parallel

  use Ethers.Contract,
    abi_file: "priv/abis/LBFactory.json",
    default_address: "0x8e42f2F4101563bF679975178e880FD87d3eFd4e"

    def fetch_pairs({_network, address} = name) do
      [pairs_count] = __MODULE__.get_number_of_lb_pairs!(to: address)

      0..pairs_count
      |> Enum.to_list
      |> pmap(&__MODULE__.get_lb_pair_at_index(&1))
      |> Enum.filter
    end
end
