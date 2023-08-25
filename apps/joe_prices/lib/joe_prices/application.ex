defmodule JoePrices.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  import Cachex.Spec

  @cache_ttl_seconds 2

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: JoePrices.PubSub},
      {Finch,
       name: JoePrices.Finch,
       pools: %{
         :default => [protocol: :http2]
       }},
      {
        DynamicSupervisor,
        [name: JoePrices.Supervisor.V21.PairRepository, strategy: :one_for_one]
      },
      {
        Registry,
        [name: JoePrices.Registry.V21.PairRepository, keys: :unique]
      },
      {
        DynamicSupervisor,
        [name: JoePrices.Supervisor.TokenInfoRepository, strategy: :one_for_one]
      },
      {
        Registry,
        [name: JoePrices.Registry.TokenInfoRepository, keys: :unique]
      },
      {
        Registry, keys: :unique, name: JoePrices.TokenRegistry
      },
      {
        DynamicSupervisor,
        [name: JoePrices.Supervisor.V1.PairRepository, strategy: :one_for_one]
      },
      {
        Registry,
        [name: JoePrices.Registry.V1.PairSupervisor, keys: :unique]
      },
      JoePrices.Boundary.V2.PairInfoCache.Cache
    ]

    v21_caches =
      JoePrices.Core.Network.all_networks()
      |> Enum.map(&v21_cache_child_from_network/1)

    v20_caches =
      JoePrices.Core.Network.all_networks()
      |> Enum.map(&v20_cache_child_from_network/1)

    v1_caches =
      JoePrices.Core.Network.all_networks()
      |> Enum.map(&v1_cache_child_from_network/1)

    opts = [strategy: :one_for_one, name: JoePrices.Supervisor]
    Supervisor.start_link(children ++ v21_caches ++ v20_caches ++ v1_caches, opts)
  end

  defp v21_cache_child_from_network(network) do
    cache_name = JoePrices.Boundary.V2.Cache.PriceCache.get_table_name(network, :v21)

    Supervisor.child_spec(
      {Cachex,
       name: cache_name,
       expiration: expiration(default: :timer.seconds(@cache_ttl_seconds)),
       interval: nil},
      id: cache_name
    )
  end

  defp v20_cache_child_from_network(network) do
    cache_name = JoePrices.Boundary.V2.Cache.PriceCache.get_table_name(network, :v20)

    Supervisor.child_spec(
      {Cachex,
       name: cache_name,
       expiration: expiration(default: :timer.seconds(@cache_ttl_seconds)),
       interval: nil},
      id: cache_name
    )
  end

  defp v1_cache_child_from_network(network) do
    cache_name = JoePrices.Boundary.V1.Cache.PriceCache.get_table_name(network)

    Supervisor.child_spec(
      {Cachex,
       name: cache_name,
       expiration: expiration(default: :timer.seconds(@cache_ttl_seconds)),
       interval: nil},
      id: cache_name
    )
  end
end
