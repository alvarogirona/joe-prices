defmodule JoePrices.Boundary.V2.Pair do
  use GenServer

  def child_spec(tokens) do
    %{
      id: {__MODULE__, via(tokens)},
      start: {__MODULE__, :start_link, tokens},
      restart: :temporary
    }
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  def start_link([token_a: _token_a, token_b: _token_b] = tokens) do
    IO.inspect(tokens)
    GenServer.start_link(__MODULE__, tokens, name: via(tokens))
  end

  def start_link(params) do
    IO.inspect(params)
    GenServer.start_link(__MODULE__, params)
  end

  def create_client(tokens) do
    DynamicSupervisor.start_child(
      JoePrices.Supervisor.V2.Pair,
      {__MODULE__, tokens}
    )
  end

  def via([token_a: token_a, token_b: token_b] = _pair) do
    pair_name = "#{token_a.address}-#{token_b.address}"
    {
      :via,
      Registry,
      {JoePrices.Registry.V2.Pair, pair_name}
    }
  end
end
