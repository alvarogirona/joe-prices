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
        [name: JoePrices.Registry.V2.Pair, keys: :unique]
      },
      {
        Registry,
        [name: JoePrices.Registry.V21.LBFactory, keys: :unique]
      },
      {
        DynamicSupervisor,
        [name: JoePrices.Supervisor.V2.Pair, strategy: :one_for_one]
      }
      # Start a worker by calling: JoePrices.Worker.start_link(arg)
      # {JoePrices.Worker, arg}
    ]

    opts = [strategy: :one_for_one, name: JoePrices.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
