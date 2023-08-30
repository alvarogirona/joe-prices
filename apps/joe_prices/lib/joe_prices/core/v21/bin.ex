defmodule JoePrices.Core.V2.Bin do
  @moduledoc """
  Module with method for v2.1 bin
  """

  @doc """
  Calculates the price for a pair given its active bin and bin step

  ## Params

  - bin_id
  - bin_step
  """
  @spec get_price_from_id(integer(), integer()) :: float
  def get_price_from_id(bin_id, bin_step) do
    :math.pow((1 + bin_step / 10_000), (bin_id - 8_388_608))
  end
end
