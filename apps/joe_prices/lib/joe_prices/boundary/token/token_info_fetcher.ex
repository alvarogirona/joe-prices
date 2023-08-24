defmodule JoePrices.Boundary.Token.TokenInfoFetcher do
  @moduledoc """
  This module is responsible for fetching and caching token information.
  It uses an Agent for each token.
  Requests for the same token are serialized, while requests for different tokens are parallelized.
  """

  require Logger
  alias JoePrices.Core.Network

  @spec start_link({atom, binary}) :: {:error, any} | {:ok, pid}
  def start_link({token, network} = key) do
    fetch_decimals(token, network)
    |> start_agent(key)
  end

  defp start_agent({:ok, decimals}, key) do
    Agent.start_link(fn -> decimals end,
      name: {:via, Registry, {JoePrices.TokenRegistry, key}}
    )
  end

  defp start_agent(_error, _key), do: {:error, :failed_to_fetch_decimals}
  @doc """
  Gets the decimal value for a token.
  First it checks if a previous agent was spawned and added to JoePrices.TokenRegistry.
  If it is not spawned then it will call `start_link`.
  If the token information is not in the cache, it fetches the token information and stores it in the cache (agent).
  If the fetch fails, it does not store the result and returns the error.

  ## Example
  ```
  iex> JoePrices.Boundary.Token.TokenInfoFetcher.get_decimals_for_token(:avalanche_mainnet, "0x49d5c2bdffac6ce2bfdb6640f4f80f226bc10bab")
  18
  ```
  """
  def get_decimals_for_token(token, network \\ :avalanche_mainnet) do
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

  defp fetch_decimals(token, network) do
    opts = Network.opts_for_call(network, token)

    with {:ok, [decimals]} <- Ethers.Contracts.ERC20.decimals(opts) do
      {:ok, decimals}
    end
  end
end
