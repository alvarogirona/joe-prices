defmodule JoePrices do
  @moduledoc """
  JoePrices keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """


  @doc """
  Returns the current price for the given tokens
  """
  def get_price_for_tokens(token_x, token_y)
      when is_binary(token_x) and is_binary(token_y) do
  end

  def get_price_for_tokens(tokens_list)
      when is_list(tokens_list) do
  end
end
