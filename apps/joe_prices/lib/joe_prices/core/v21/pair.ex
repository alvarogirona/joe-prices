defmodule JoePrices.Core.V2.Pair do
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
end
