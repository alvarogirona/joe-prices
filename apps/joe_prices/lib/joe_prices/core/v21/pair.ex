defmodule JoePrices.Core.V21.Pair do
  alias JoePrices.Core.Tokens.USDCe
  alias JoePrices.Core.Tokens.USDT
  alias JoePrices.Core.Tokens.USDC

  defstruct address: "",
            network: :avalanche_mainnet,
            version: :v21,
            name: "",
            token_x: "",
            token_y: "",
            bin_step: 0,
            active_bin: 0,
            price: 0

  @type t() :: %__MODULE__{
          address: String.t(),
          network: String.t(),
          version: :v20 | :v21,
          name: String.t(),
          token_x: String.t(),
          token_y: String.t(),
          bin_step: integer(),
          active_bin: integer(),
          price: float()
        }

  @avax_wavax_address "0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7"
  @arb_weth_address "0x82af49447d8a07e3bd95bd0d56f35241523fbab1"
  @bsc_wbnb_address "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c"

  @spec primary_quote_assets(:arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet) :: list(String.t())
  def primary_quote_assets(:avalanche_mainnet = network) do
    [
      USDC.address_for_network(network),
      USDT.address_for_network(network),
      @avax_wavax_address
    ]
  end

  def primary_quote_assets(:arbitrum_mainnet = network) do
    [
      USDC.address_for_network(network),
      USDT.address_for_network(network),
      USDCe.address_for_network(network),
      @arb_weth_address
    ]
  end

  def primary_quote_assets(:bsc_mainnet = network) do
    [
      USDT.address_for_network(network),
      @bsc_wbnb_address
    ]
  end

  @spec is_primary_quote_asset?(String.t(), :arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet) ::
          boolean
  def is_primary_quote_asset?(token_address, network) do
    downcased_token = String.downcase(token_address)

    primary_quote_assets(network)
    |> Enum.member?(downcased_token)
  end
end
