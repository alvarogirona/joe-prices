defmodule JoePrices.Boundary.V1.PriceRequest do
  @moduledoc """
  Struct definition for a v1 price request.
  """

  defstruct [:base_asset, :quote_asset]

  @type t :: %__MODULE__{
    base_asset: String.t(),
    quote_asset: String.t()
  }
end
