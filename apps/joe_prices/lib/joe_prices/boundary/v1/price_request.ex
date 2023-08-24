defmodule JoePrices.Boundary.V1.PriceRequest do
  @type network_name :: :arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet

  @moduledoc """
  Struct definition for a v1 price request.

  ## Example

  ```elixir
  # Joe/USDC
  iex> request = %JoePrices.Boundary.V1.PriceRequest{base_asset: "0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd", quote_asset: "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e"}

  # USDC/Joe
  iex> request2 = %JoePrices.Boundary.V1.PriceRequest{base_asset: "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e", quote_asset: "0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd"}
  ```
  """
  defstruct base_asset: "",
    quote_asset: "",
    network: :avalanche_mainnet

  @type t :: %__MODULE__{
    base_asset: String.t(),
    quote_asset: String.t(),
    network: network_name()
  }
end
