defmodule JoePrices.Core.V21.Pair do
  alias JoePrices.Core.V21.Token

  @enforce_keys [:name, :tokens, :bin_step, :active_bin, :price, :updated_at]

  defstruct name: "",
    tokens: %{
      token_x: %Token{},
      token_y: %Token{}
    },
    bin_step: 0,
    active_bin: 0,
    price: 0,
    updated_at: 0

  @type t() :: %__MODULE__{
    name: String.t(),
    bin_step: integer(),
    active_bin: integer(),
    price: integer(),
    updated_at: %Time{}
  }
end
