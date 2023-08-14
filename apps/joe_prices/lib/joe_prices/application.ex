defmodule JoePrices.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      JoePrices.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: JoePrices.PubSub},
      # Start Finch
      {Finch, name: JoePrices.Finch},
      {
        Registry,
        [name: JoePrices.Registry.V21.Cache.PriceCache, keys: :unique]
      },
      {
        Registry,
        [name: JoePrices.Registry.Common.TokenInfoCache, keys: :unique]
      },
      # Start a worker by calling: JoePrices.Worker.start_link(arg)
      # {JoePrices.Worker, arg}
    ]

    caches = JoePrices.Core.Network.all_networks
     |> Enum.map(&cache_child_from_network(&1))

    token_caches = JoePrices.Core.Network.all_networks
     |> Enum.map(&token_cache_child_from_network(&1))

    opts = [strategy: :one_for_one, name: JoePrices.Supervisor]
    Supervisor.start_link(children ++ caches ++ token_caches, opts)
  end

  defp cache_child_from_network(network) do
    {
      JoePrices.Boundary.V21.Cache.PriceCache,
      [network: network]
    }
  end

  defp token_cache_child_from_network(network) do
    {
      JoePrices.Boundary.Common.TokenInfoCache,
      [network: network]
    }
  end
end
