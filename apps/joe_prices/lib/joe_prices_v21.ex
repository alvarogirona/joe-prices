defmodule JoePricesV21 do

  alias JoePrices.Boundary.V21.PriceCache

  @doc """
  Returns the current price for the given tokens
  """
  def get_price_for_tokens(token_x, token_y)
      when is_binary(token_x) and is_binary(token_y) do
  end

  @doc """
  Returns the prices for a list of tokens.

  Format of the list: [(token_x, token_y)]
  """
  def get_price_for_tokens(tokens_list)
      when is_list(tokens_list) do
  end
end
