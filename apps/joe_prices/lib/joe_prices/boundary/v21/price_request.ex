defmodule JoePrices.Boundary.V21.PriceRequest do
  defstruct token_x_address: "",
    token_y_address: "",
    bin_step: 0

    @type t :: %__MODULE__{
      token_x_address: String.t(),
      token_y_address: String.t(),
      bin_step: integer()
    }
end
