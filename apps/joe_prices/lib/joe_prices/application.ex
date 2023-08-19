defmodule JoePrices.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  import Cachex.Spec

  @cache_ttl_seconds 5

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      # Start the PubSub system
      {Phoenix.PubSub, name: JoePrices.PubSub},
      # Start Finch
      {Finch,
       name: JoePrices.Finch,
       pools: %{
         :default => [protocol: :http2],
       }
      },
      {
        DynamicSupervisor,
        [name: JoePrices.Supervisor.V21.PairRepository, strategy: :one_for_one]
      },
      {
        Registry,
        [name: JoePrices.Registry.V21.PairRepository, keys: :unique]
      }
      # Start a worker by calling: JoePrices.Worker.start_link(arg)
      # {JoePrices.Worker, arg}
    ]

    v21_caches =
      JoePrices.Core.Network.all_networks()
      |> Enum.map(&v21_cache_child_from_network(&1))

    opts = [strategy: :one_for_one, name: JoePrices.Supervisor]
    Supervisor.start_link(children ++ v21_caches, opts)
  end

  defp v21_cache_child_from_network(network) do
    Supervisor.child_spec(
      {
        Cachex,
        [
          name: JoePrices.Boundary.V21.Cache.PriceCache.get_table_name(network),
          expiration: expiration(default: :timer.seconds(@cache_ttl_seconds)),
          # Just lazy expiration, no background ttl process.
          interval: nil
        ]
      },
      id: make_ref()
    )
  end
end
