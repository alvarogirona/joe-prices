defmodule JoePrices.Boundary.Token.TokenInfoFetcher do
  @moduledoc """
  This module is responsible for fetching and caching token information.
  It uses an Agent for each token.
  Requests for the same token are serialized, while requests for different tokens are parallelized.
  """

  require Logger
  alias JoePrices.Core.Network

  @spec start_link({atom, binary}) :: {:error, any} | {:ok, pid}
  def start_link({network, token}) do
    case fetch_decimals(network, token) do
      {:ok, decimals} ->
        Agent.start_link(fn -> decimals end,
          name: {:via, Registry, {JoePrices.TokenRegistry, {network, token}}}
        )

      _error ->
        {:error, :failed_to_fetch_decimals}
    end
  end

  @doc """
  Gets the decimal value for a token.
  If the token information is not in the cache, it fetches the token information and stores it in the cache.
  If the fetch fails, it does not store the result and returns the error.

  ## Example
  ```
  iex> JoePrices.Boundary.Token.TokenInfoFetcher.get_decimals_for_token(:avalanche_mainnet, "0x49d5c2bdffac6ce2bfdb6640f4f80f226bc10bab")
  18
  ```
  """
  def get_decimals_for_token(network, token) do
    case Registry.whereis_name({JoePrices.TokenRegistry, {network, token}}) do
      :undefined ->
        case start_link({network, token}) do
          {:ok, pid} -> Agent.get(pid, & &1)
          {:error, {:already_started, pid}} -> Agent.get(pid, & &1)
          {:error, _} -> {:error, :failed_to_fetch_decimals}
        end

      pid ->
        Agent.get(pid, & &1)
    end
  end

  defp fetch_decimals(network, token) do
    opts = Network.opts_for_call(network, token)

    with {:ok, [decimals]} <- Ethers.Contracts.ERC20.decimals(opts) do
      {:ok, decimals}
    end
  end
end
