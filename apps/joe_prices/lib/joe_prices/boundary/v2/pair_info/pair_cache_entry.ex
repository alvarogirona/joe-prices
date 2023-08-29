defmodule JoePrices.Boundary.V2.PairInfoCache.PairCacheEntry do
  @derive Jason.Encoder
  defstruct [:pair_address, :token_x, :token_y, :name, :bin_step]

  @type t() :: %__MODULE__{
    pair_address: String.t(),
    token_x: String.t(),
    token_y: String.t(),
    name: String.t(),
    bin_step: non_neg_integer()
  }

  def new(map) do
    %__MODULE__{
      pair_address: map["pair_address"],
      token_x: map["token_x"],
      token_y: map["token_y"],
      name: map["name"],
      bin_step: map["bin_step"]
    }
  end
end
