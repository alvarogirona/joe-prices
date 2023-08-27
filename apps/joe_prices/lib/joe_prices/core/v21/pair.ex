defmodule JoePrices.Core.V21.Pair do
  @enforce_keys [:name, :token_x, :token_y, :bin_step, :active_bin]

  defstruct name: "",
            token_x: "",
            token_y: "",
            bin_step: 0,
            active_bin: 0,
            price: 0

  @type t() :: %__MODULE__{
          name: String.t(),
          token_x: String.t(),
          token_y: String.t(),
          bin_step: integer(),
          active_bin: integer(),
          price: float()
        }
end
