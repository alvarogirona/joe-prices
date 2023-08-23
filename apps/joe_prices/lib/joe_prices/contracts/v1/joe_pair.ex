defmodule JoePrices.Contracts.V1.JoePair do
  use Ethers.Contract,
    abi_file: "priv/abis/v1/pair.json"

  alias JoePrices.Boundary.Token.TokenInfoFetcher
  alias JoePrices.Core.Network

  @doc """
  ## Example

  ```
  iex> JoePrices.Contracts.V1.JoePair.fetch_price("0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7", "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e", "0xf4003f4efbe8691b60249e6afbd307abe7758adb", :avalanche_mainnet)
  ```
  """
  def fetch_price(token_x_address, token_y_address, pair, network) do
    opts = Network.opts_for_call(network, pair)

    token_x_decimals = TokenInfoFetcher.get_decimals_for_token(network, token_x_address)
    token_y_decimals = TokenInfoFetcher.get_decimals_for_token(network, token_y_address)

    with {:ok, [reserve_x, reserve_y, _block_timestamp]} <- __MODULE__.get_reserves(opts) do
      if token_x_address < token_y_address do
        (reserve_y / reserve_x) * :math.pow(10, token_x_decimals - token_y_decimals)
      else
        (reserve_x / reserve_y) * :math.pow(10, token_x_decimals - token_y_decimals)
      end
    end
  end
end
