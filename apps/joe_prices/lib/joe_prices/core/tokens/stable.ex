defmodule JoePrices.Core.Tokens.Stable do
  @moduledoc """
  Module to check if a given token for a network is an stable coin.
  """

  alias JoePrices.Core.Tokens.USDC
  alias JoePrices.Core.Tokens.USDCe
  alias JoePrices.Core.Tokens.USDT

  @callback address_for_network(network :: atom()) :: String.t()

  @doc """
  Checks if a token is an stable coin.

  ## Examples

      iex> JoePrices.Core.Tokens.Stable.is_token_stable("0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e", :avalanche_mainnet)
      true

      iex> JoePrices.Core.Tokens.Stable.is_token_stable("0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6v", :avalanche_mainnet)
      false
  """
  def is_token_stable(token_address, network) do
    downcased_token = String.downcase(token_address)

    stable_coin_modules()
    |> Enum.map(fn module -> apply(module, :address_for_network, [network]) end)
    |> Enum.member?(downcased_token)
  end

  defp stable_coin_modules(), do: [USDC, USDT, USDCe]
end
