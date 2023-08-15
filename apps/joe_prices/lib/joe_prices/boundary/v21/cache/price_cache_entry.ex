defmodule JoePrices.Boundary.V21.Cache.PriceCacheEntry do
  defstruct token_x: "",
    token_y: "",
    bin_step: 0,
    active_bin: 0

  def new(pair = %JoePrices.Core.V21.Pair{}) do
    %__MODULE__{
      token_x: pair.token_x,
      token_y: pair.token_y,
      bin_step: pair.bin_step,
      active_bin: pair.active_bin
    }
  end
end
