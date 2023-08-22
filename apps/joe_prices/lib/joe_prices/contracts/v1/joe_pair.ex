defmodule JoePrices.Contracts.V1.JoePair do
  use Ethers.Contract,
    abi_file: "priv/abis/v1/pair.json"

  alias JoePrices.Core.Network

  @doc """
  ## Example

  ```
  iex> JoePrices.Contracts.V1.JoePair.fetch_price("0xf4003f4efbe8691b60249e6afbd307abe7758adb", :avalanche_mainnet)
  ```
  """
  def fetch_price(pair, network) do
    opts = Network.opts_for_call(network, pair)

    with {:ok, [total, token_x, token_y]} <- __MODULE__.get_reserves(opts) do
      token_x / token_y
    end
  end
end
