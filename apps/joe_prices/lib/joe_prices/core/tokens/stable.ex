defmodule JoePrices.Core.Tokens.Stable do
  alias JoePrices.Core.Tokens.USDC
  alias JoePrices.Core.Tokens.USDCe
  alias JoePrices.Core.Tokens.USDT

  @callback address_for_network(network :: atom()) :: String.t()

  def is_token_stable(token_address, network) do
    stable_coin_modules()
    |> Enum.map(fn module -> apply(module, :address_for_network, [network]) end)
    |> Enum.member?(token_address)
  end

  def stable_coin_modules(), do: [USDC, USDT, USDCe]
end
