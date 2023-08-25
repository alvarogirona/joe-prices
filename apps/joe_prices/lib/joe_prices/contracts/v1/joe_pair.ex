defmodule JoePrices.Contracts.V1.JoePair do
  use Ethers.Contract,
    abi_file: "priv/abis/v1/pair.json"

  alias JoePrices.Boundary.Token.TokenInfoFetcher
  alias JoePrices.Core.Network

  defstruct [:token_x, :token_y, :price, :inverse_price]

  @type t :: %__MODULE__{
    token_x: String.t(),
    token_y: String.t(),
    price: float(),
    inverse_price: float()
  }

  @doc """
  ## Example

  ```
  # avax as base and usdc as quote (AVAX addr < usdc addr)
  iex> JoePrices.Contracts.V1.JoePair.fetch_price("0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7", "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e", "0xf4003f4efbe8691b60249e6afbd307abe7758adb", :avalanche_mainnet)
  %JoePrices.Contracts.V1.JoePair{..., price: 10.417097964716191}

  # USDC as base asset, AVAX as quote
  iex> JoePrices.Contracts.V1.JoePair.fetch_price("0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e", "0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7", "0xf4003f4efbe8691b60249e6afbd307abe7758adb", :avalanche_mainnet)
  %JoePrices.Contracts.V1.JoePair{..., price: 0.09599602532174557}

  # joe as base and avax as quote (joe addr > avax addr)
  iex> JoePrices.Contracts.V1.JoePair.fetch_price("0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd", "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7", "0x454E67025631C065d3cFAD6d71E6892f74487a15", :avalanche_mainnet)
  %JoePrices.Contracts.V1.JoePair{..., price: 0.02325319838557763}

  # Wavax as base asset, joe as quote asset
  iex> JoePrices.Contracts.V1.JoePair.fetch_price("0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7", "0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd", "0x454E67025631C065d3cFAD6d71E6892f74487a15", :avalanche_mainnet)
  %JoePrices.Contracts.V1.JoePair{..., price: 43.00483672905107}

  # Joe/USDC
  iex> JoePrices.Contracts.V1.JoePair.fetch_price("0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd", "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e", "0x3bc40d4307cd946157447cd55d70ee7495ba6140", :avalanche_mainnet)
  %JoePrices.Contracts.V1.JoePair{..., price: 0.24237292162558619}

  # USDC/Joe
  iex> JoePrices.Contracts.V1.JoePair.fetch_price("0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e", "0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd", "0x3bc40d4307cd946157447cd55d70ee7495ba6140", :avalanche_mainnet)
  %JoePrices.Contracts.V1.JoePair{..., price: 4.125873440370472}
  ```
  """
  @spec fetch_price(String.t(), String.t(), String.t(), atom()) ::{:ok, %__MODULE__{}} | {:error, term()}
  def fetch_price(base_asset, quote_asset, pair, network) do
    opts = Network.opts_for_call(network, pair)

    base_asset_decimals = TokenInfoFetcher.get_decimals_for_token(base_asset, network)
    quote_asset_decimals = TokenInfoFetcher.get_decimals_for_token(quote_asset, network)

    with {:ok, [reserve_x, reserve_y, _block_timestamp]} <- __MODULE__.get_reserves(opts) do
      if base_asset < quote_asset do
        price = (reserve_y / reserve_x) * :math.pow(10, base_asset_decimals - quote_asset_decimals)

        {:ok, %__MODULE__{
          token_x: base_asset,
          token_y: quote_asset,
          price: price,
          inverse_price: 1 / price
        }}
      else
        price = (reserve_x / reserve_y) * :math.pow(10, base_asset_decimals - quote_asset_decimals)

        {:ok, %__MODULE__{
          token_x: quote_asset,
          token_y: base_asset,
          price: 1 / price,
          inverse_price: price
        }}
      end
    end
  end
end
