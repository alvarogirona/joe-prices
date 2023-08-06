defmodule JoePrices.Core.V1.Token do

  defstruct decimals: 18,
    address: "",
    symbol: "",
    name: "",
    is_native: false,
    is_token: false,
    chain_id: 0

  @spec equals(%__MODULE__{}, %__MODULE__{}) :: boolean()
  def equals(token_a = %__MODULE__{}, token_b = %__MODULE__{}) do
      token_a.address == token_b.address &&
        token_a.chain_id == token_b.chain_id
  end
end
