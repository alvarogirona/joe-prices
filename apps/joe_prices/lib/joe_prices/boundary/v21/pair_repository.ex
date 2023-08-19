defmodule JoePrices.Boundary.V21.PairRepository do
  use GenServer

  alias JoePrices.Boundary.V21.PriceRequest

  def get_price(request = %PriceRequest{}) do
    
  end

  def child_spec(request = %PriceRequest{}) do
    %{
      id: {__MODULE__, {request.network, request.token_x, request.token_y, request.bin_step}},
      start: {__MODULE__, :start_link, [request]},
      restart: :temporary,
      name: via(request)
    }
  end

  def start_link(request = %PriceRequest{}) do
    GenServer.start_link(
      __MODULE__,
      request,
      name: via(request)
    )
  end

  defp via(request = %PriceRequest{}) do
    {
      :via,
      Registry,
      {JoePrices.Registry.V21.PairRepository, request},
    }
  end

  defp fetch_process(request = %PriceRequest{}) do
    child_spec = child_spec(request)

    child = DynamicSupervisor.start_child(
      JoePrices.Supervisor.V21.PairRepository,
      {__MODULE__, request}
    )

    case child do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:error, _} = err -> err
    end
  end
end
