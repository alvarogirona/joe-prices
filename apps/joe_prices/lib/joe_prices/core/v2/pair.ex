defmodule JoePrices.Core.V2.Pair do
  alias JoePrices.Core.V1.Token

  defstruct token_x: %Token{},
    token_y: %Token{}

  @spec get_all_possible_pairs(list(%Token{})) :: list()
  def get_all_possible_pairs(tokens) do
    for token_x <- tokens, token_y <- tokens, !Token.equals(token_x, token_y) do
      [token_x, token_y]
    end
  end
end
