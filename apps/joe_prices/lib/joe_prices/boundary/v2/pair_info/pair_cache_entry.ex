defmodule JoePrices.Boundary.V2.PairInfoCache.PairCacheEntry do
  defstruct [:pair_address, :token_x, :token_y, :name, :bin_step]

  @type t() :: %__MODULE__{
    pair_address: String.t(),
    token_x: String.t(),
    token_y: String.t(),
    name: String.t(),
    bin_step: non_neg_integer()
  }
end
