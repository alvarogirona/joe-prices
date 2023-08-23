defmodule JoePrices.Boundary.V1.PriceRequest do
  @moduledoc """
  Struct definition for a v1 price request.
  """

  defstruct [:token_x, :token_y]

  @type t :: %__MODULE__{
    token_x: String.t(),
    token_y: String.t()
  }
end
