defmodule JoePrices.Boundary.V2.PriceRequest do
  @moduledoc """
  Struct definition for a v2.1 price request.

  ```
  alias JoePrices.Boundary.V2.PriceRequest
  tx = "0x49d5c2bdffac6ce2bfdb6640f4f80f226bc10bab"
  ty = "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e"
  bs = 15
  price_request = %PriceRequest{token_x: tx, token_y: ty, bin_step: bs, network: :avalanche_mainnet, version: :v21}
  """

  defstruct token_x: "",
            token_y: "",
            bin_step: 0,
            network: :avalanche_mainnet,
            version: :v21

  @type t :: %__MODULE__{
          token_x: String.t(),
          token_y: String.t(),
          bin_step: integer(),
          network: atom(),
          version: atom
        }
end
