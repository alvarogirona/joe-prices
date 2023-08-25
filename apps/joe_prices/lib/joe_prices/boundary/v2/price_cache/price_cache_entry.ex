defmodule JoePrices.Boundary.V2.PriceCache.PriceCacheEntry do
  @moduledoc """
  Module with struct definition of a cache entry for v2.1
  """
alias JoePrices.Boundary.Token.TokenInfoFetcher

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
  Creates a new cache entry from a `V21.Pair`
  """
  @spec new(JoePrices.Core.V21.Pair.t()) :: __MODULE__.t()
  def new(pair = %JoePrices.Core.V21.Pair{}) do
    token_x_decimals = TokenInfoFetcher.get_decimals_for_token(pair.token_x)
    token_y_decimals = TokenInfoFetcher.get_decimals_for_token(pair.token_y)
    raw_price = JoePrices.Core.V21.Bin.get_price_from_id(pair.active_bin, pair.bin_step)
    price_multiplier = :math.pow(10, token_x_decimals - token_y_decimals)

    price =
      if pair.token_x < pair.token_y do
        raw_price * price_multiplier
      else
        1 / raw_price * price_multiplier
      end

    %__MODULE__{
      token_x: pair.token_x,
      token_y: pair.token_y,
      bin_step: pair.bin_step,
      active_bin: pair.active_bin,
      price: price
    }
  end
end
