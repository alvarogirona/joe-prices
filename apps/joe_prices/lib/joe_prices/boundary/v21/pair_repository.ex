defmodule JoePrices.Boundary.V21.PairRepository do
  @moduledoc """
  GenServer definition for a v2.1 pair repository.

  Used to serialize requests to the same pair to avoid duped calls when cache is invalid.
  """

  use GenServer

  alias JoePrices.Boundary.V21.PriceRequest
  alias JoePrices.Boundary.V21.Cache.PriceCache
  alias JoePrices.Boundary.V21.Cache.PriceCacheEntry
  alias JoePrices.Core.V21.Pair

  @bad_resp_addr "0x0000000000000000000000000000000000000000"

  @doc """
  Returns the price for a given pair.
  """
  @spec get_price(PriceRequest.t()) :: PriceCacheEntry.t()
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
    pair_info = PriceCache.get_price(:avalanche_mainnet, request)
    |> maybe_update_cache?(request)

    {:reply, pair_info, request}
  end

  defp maybe_update_cache?({:ok, nil} = _resp, request = %PriceRequest{}) do
    %{:token_x => tx, :token_y => ty, :bin_step => bin_step} = request

    case lb_factory_module(request.version).fetch_pairs_for_tokens(request.network, tx, ty, bin_step) do
      {:ok, pairs} ->
        [info] = fetch_pairs_info(pairs, network: request.network, version: request.version)
        PriceCache.update_prices(request.network, [info])
        {:ok, PriceCacheEntry.new(info)}
      _ ->
        {:error, "LBFactory contract call error (fetch_pairs_for_tokens)"}
    end
  end

  defp maybe_update_cache?({:ok, value} = _resp, _request) do
    value
  end

  defp fetch_pairs_info(pairs, network: network, version: version) do
    pairs
    |> Enum.map(fn pair ->
      case pair do
        {_, @bad_resp_addr, _, _} ->
          nil

        {_, addr, _, _} ->
          [token_x, token_y] = lb_pair_module(version).fetch_tokens(network, addr)

          {:ok, bin_step} = lb_pair_module(version).fetch_bin_step(network, addr)
          {:ok, [active_bin]} = lb_pair_module(version).fetch_active_bin_id(network, addr)

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

  @spec init(any) :: {:ok, any}
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

  @spec start_link(JoePrices.Boundary.V21.PriceRequest.t()) ::
          :ignore | {:error, any} | {:ok, pid}
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

  @spec fetch_process(PriceRequest.t()) :: {:error, any} | {:ok, pid()}
  def fetch_process(request = %PriceRequest{}) do
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

  @spec lb_factory_module(atom()) :: any()
  defp lb_factory_module(:v20), do: JoePrices.Contracts.V20.LbFactory
  defp lb_factory_module(:v21), do: JoePrices.Contracts.V21.LbFactory
  defp lb_factory_module(_), do: raise "Invalid version provided to lb_factory_module"

  @spec lb_factory_module(atom()) :: any()
  defp lb_pair_module(:v20), do: JoePrices.Contracts.V20.LbPair
  defp lb_pair_module(:v21), do: JoePrices.Contracts.V21.LbPair
  defp lb_pair_module(_), do: raise "Invalid version provided to lb_factory_module"
end
