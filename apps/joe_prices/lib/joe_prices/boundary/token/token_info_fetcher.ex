defmodule JoePrices.Boundary.Token.TokenInfoFetcher do
  @moduledoc """
  This module is responsible for fetching and caching token information.
  It uses a Registry to manage an Agent for each token.
  Requests for the same token are serialized, while requests for different tokens are parallelized.
  """

  require Logger
  alias JoePrices.Core.Network

  @doc """
  Starts the Registry for token Agents.
  """
  def start_link(_) do
    Registry.start_link(keys: :unique, name: JoePrices.TokenRegistry)
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [[]]},
      type: :worker
    }
  end

  @doc """
  Gets the information for a token.
  If the token information is not in the cache, it fetches the token information and stores it in the cache.

  ## Example

  ```
  iex> JoePrices.Boundary.Token.TokenInfoFetcher.get_decimals_for_token(:avalanche_mainnet, "0x49d5c2bdffac6ce2bfdb6640f4f80f226bc10bab")
  18
  ```
  """
  @spec get_decimals_for_token(any, any) :: non_neg_integer() | {:error, any()}
  def get_decimals_for_token(network, address) do
    case Registry.lookup(JoePrices.TokenRegistry, {network, address}) do
      [] ->
        case fetch_token_info_from_rpc(address) do
          {:ok, decimals} ->
            {:ok, pid} = Agent.start_link(fn -> decimals end)
            Registry.register(JoePrices.TokenRegistry, address, pid)
            {:ok, decimals}

          error ->
            error
        end

      [{_pid, agent}] ->
        Agent.get(agent, & &1)
    end
  end

  defp fetch_token_info_from_rpc(address) do
    # Fetch the number of decimals that the token has.
    opts = Network.opts_for_call(:avalanche_mainnet, address)

    with {:ok, [decimals]} <- Ethers.Contracts.ERC20.decimals(opts) do
      decimals
    end
  end
end
