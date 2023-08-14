defmodule JoePrices.Boundary.Common.TokenInfoCache do
  use GenServer

  @ets_table_suffix :token_info_cache

  @type network_name :: :arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet

  def init([network: network] = args) do
    create_ets_table(network)

    {:ok, args}
  end

  def child_spec([network: network] = opts) do
    %{
      id: via(network),
      start: {__MODULE__, :start_link, opts},
      shutdown: 30_000,
      restart: :permanent,
      type: :worker
    }
  end

  def start_link({:network, network}) do
    GenServer.start_link(
      __MODULE__,
      [network: network],
      name: via(network)
    )
  end

  # def set_tokens(tokens, [network: network] = _opts) do
  #   table_name = get_table_name(network)
  # end

  @doc """
  ## Example
   iex> token = %JoePrices.Core.V21.Token{name: "name", address: "asdf"}
   iex> JoePrices.Boundary.Common.TokenInfoCache.set_token(token, network: :avalanche_mainnet)
  """
  def set_token(token = %JoePrices.Core.V21.Token{}, [network: network] = _opts) do
    table_name = get_table_name(network)

    :ets.insert(table_name, {1, token})
  end

  def lookup(_token_address) do

  end

  defp create_ets_table(network) when is_atom(network) do
    table_name = get_table_name(network)
    :ets.new(table_name, [:set, :protected, :named_table])
  end

  defp get_table_name(network) when is_atom(network) do
    (Atom.to_string(network) <> "_" <> Atom.to_string(@ets_table_suffix))
    |> String.to_atom
  end


  defp via(network) do
    {
      :via,
      Registry,
      {JoePrices.Registry.Common.TokenInfoCache, network},
    }
  end
end
