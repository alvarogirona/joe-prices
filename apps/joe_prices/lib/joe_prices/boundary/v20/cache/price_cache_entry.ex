defmodule JoePrices.Boundary.V20.Cache.PriceCacheEntry do
  @moduledoc """
  Module with struct definition of a cache entry for v2.0
  """

  alias JoePrices.Core.V20.Pair

  defstruct token_x: "",
            token_y: "",
            bin_step: 0,
            active_bin: 0,
            price: 0

  @type t :: %__MODULE__{
          token_x: String.t(),
          token_y: String.t(),
          bin_step: integer(),
          active_bin: integer(),
          price: float()
        }

  @doc """
  Creates a new cache entry from a `V20.Pair`
  """
  @spec new(JoePrices.Core.V20.Pair.t()) :: JoePrices.Boundary.V20.Cache.PriceCacheEntry.t()
  def new(pair = %Pair{}) do
    %__MODULE__{
      token_x: pair.token_x,
      token_y: pair.token_y,
      bin_step: pair.bin_step,
      active_bin: pair.active_bin,
      price: "WIP"
    }
  end
end
