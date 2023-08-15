defmodule JoePrices.Boundary.V21.PriceRequest do
  @moduledoc """
  Struct definition for a v2.1 price request.
  """

  defstruct token_x: "",
            token_y: "",
            bin_step: 0

  @type t :: %__MODULE__{
          token_x: String.t(),
          token_y: String.t(),
          bin_step: integer()
        }
end
