defmodule JoePrices.Core.V21.Bin do
  def get_price_from_id(bin_id, bin_step) do
    (1 + bin_step / 10_000) ** (bin_id - 8388608)
  end
end
