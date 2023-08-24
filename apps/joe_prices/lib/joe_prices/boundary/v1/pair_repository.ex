defmodule JoePrices.Boundary.V1.PairRepository do
  alias JoePrices.Contracts.V1.JoePair
  alias JoePrices.Boundary.V1.PriceRequest
  use GenServer

  @spec get_price(PriceRequest.t()) :: JoePair.t()
  def get_price(%PriceRequest{} = request) do
    with {:ok, pid} <- fetch_process(request) do
      GenServer.call(pid, :fetch_price)
    end
  end


  def init(params) do
    {:ok, params}
  end

  def start_link({[_token_x, _token_y], network} = params) do
    GenServer.start_link(
      __MODULE__,
      params,
      name: via(params)
    )
  end

  def via({tokens, network} = params) do
    {
      :via,
      Registry,
      {JoePrices.Registry.V1.PairSupervisor, {tokens, network}}
    }
  end

  def fetch_process(%PriceRequest{} = request) do
    proc_key = process_key_for_request(request)

    child = DynamicSupervisor.start_child(
      JoePrices.Supervisor.V1.PairRepository,
      {__MODULE__, {proc_key, request.network}}
    )

    case child do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:error, _} = err -> err
    end
  end

  @spec process_key_for_request(PriceRequest.t()) :: list()
  def process_key_for_request(%PriceRequest{} = request) do
    [request.base_asset, request.quote_asset]
    |> Enum.sort()
  end
end
