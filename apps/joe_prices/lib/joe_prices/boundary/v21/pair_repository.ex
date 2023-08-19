defmodule JoePrices.Boundary.V21.PairRepository do
  use GenServer

  alias JoePrices.Boundary.V21.PriceRequest
  alias JoePrices.Boundary.V21.Cache.PriceCache
  alias JoePrices.Boundary.V21.Cache.PriceCacheEntry
  alias JoePrices.Core.V21.Pair

  @bad_resp_addr "0x0000000000000000000000000000000000000000"

  def get_price(request = %PriceRequest{}) do
    with {:ok, pid} <- fetch_process(request) do
      GenServer.call(pid, :fetch_price)
    end
  end

  @doc """
  ```
  {:ok, pid} = JoePrices.Boundary.V21.PairRepository.fetch_process(price_request)
  GenServer.call(pid, :fetch_price)
  ```
  """
  def handle_call(:fetch_price, _from, request = %PriceRequest{}) do
    pair_info = JoePrices.Boundary.V21.Cache.PriceCache.get_price(:avalanche_mainnet, request)
    |> maybe_update_cache?(request, request.network)

    {:reply, pair_info, request}
  end

  defp maybe_update_cache?({:ok, nil} = _resp, request = %PriceRequest{}, network) do
    %{:token_x => tx, :token_y => ty, :bin_step => bin_step} = request

    case JoePrices.Contracts.V21.LbFactory.fetch_pairs_for_tokens(network, tx, ty, bin_step) do
      {:ok, pairs} ->
        [info] = fetch_pairs_info(pairs, network: network)
        PriceCache.update_prices(network, [info])
        {:ok, info}
      _ ->
        {:error, "LBFactory contract call error (fetch_pairs_for_tokens)"}
    end
  end

  defp maybe_update_cache?({:ok, value} = _resp, _request, _network) do
    value
  end

  defp fetch_pairs_info(pairs, network: network) do
    pairs
    |> Enum.map(fn pair ->
      case pair do
        {_, @bad_resp_addr, _, _} ->
          nil

        {_, addr, _, _} ->
          [token_x, token_y] = JoePrices.Contracts.V21.LbPair.fetch_tokens(network, addr)

          {:ok, bin_step} = JoePrices.Contracts.V21.LbPair.fetch_bin_step(network, addr)
          {:ok, [active_bin]} = JoePrices.Contracts.V21.LbPair.fetch_active_bin_id(network, addr)

          %Pair{
            name: "",
            token_x: token_x,
            token_y: token_y,
            bin_step: bin_step,
            active_bin: active_bin
          }
      end
    end)
  end

  def init(args) do
    {:ok, args}
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

  def fetch_process(request = %PriceRequest{}) do
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
