defmodule JoePrices.Boundary.V1.PairRepository do
  alias JoePrices.Boundary.V1.PriceCache.PriceCache
  alias JoePrices.Contracts.V1.JoePair
  alias JoePrices.Boundary.V1.PriceRequest
  use GenServer

  @doc """

  ## Example
  iex> request = %JoePrices.Boundary.V1.PriceRequest{base_asset: "0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd", quote_asset: "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e"}
  iex> JoePrices.Boundary.V1.PairRepository.get_price(request)
  """
  @spec get_price(PriceRequest.t()) :: JoePair.t()
  def get_price(%PriceRequest{} = request) do
    with {:ok, pid} <- fetch_process(request) do
      GenServer.call(pid, {:fetch_price, request})
    end
  end

  def handle_call({:fetch_price, request}, _from,  proc_id) do
    pair_info = PriceCache.get_price(request)
    |> maybe_update_cache?(request)

    {:reply, pair_info, proc_id}
  end

  defp maybe_update_cache?({:ok, nil}, %PriceRequest{} = request), do: update_cache(request)
  defp maybe_update_cache?(cache_entry, _request), do: cache_entry

  @spec update_cache(JoePrices.Boundary.V1.PriceRequest.t()) :: JoePair.t()
  def update_cache(%PriceRequest{base_asset: base_asset, quote_asset: quote_asset, network: network}) do
    {:ok, pair} = JoePrices.Contracts.V1.JoeFactory.fetch_pair(quote_asset, base_asset, network)
    price_response = JoePair.fetch_price(base_asset, quote_asset, pair, network)

    case price_response do
      {:error, _} = error -> error
      {:ok, pair_struct} = ok_resp ->
        PriceCache.update_price(network, pair_struct)
        ok_resp
    end
  end

  @spec fetch_process(JoePrices.Boundary.V1.PriceRequest.t()) :: {:error, any} | {:ok, any}
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

  @spec init(any) :: {:ok, any}
  def init(params) do
    {:ok, params}
  end

  @spec start_link({[...], any}) :: :ignore | {:error, any} | {:ok, pid}
  def start_link({[_token_x, _token_y], _network} = params) do
    GenServer.start_link(
      __MODULE__,
      params,
      name: via(params)
    )
  end

  defp via({_tokens, _network} = params) do
    {
      :via,
      Registry,
      {JoePrices.Registry.V1.PairSupervisor, params}
    }
  end

  @spec process_key_for_request(PriceRequest.t()) :: list()
  defp process_key_for_request(%PriceRequest{} = request) do
    [request.base_asset, request.quote_asset]
    |> Enum.sort()
  end
end
