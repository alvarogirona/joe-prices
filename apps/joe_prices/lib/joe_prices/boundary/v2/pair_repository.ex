defmodule JoePrices.Boundary.V2.PairRepository do
  @moduledoc """
  GenServer definition for a v2 pair repository.

  Each requested pair spawns its own process dynamically.

  Used to serialize requests to the same pair to avoid duped calls when cache is invalid.
  """

  use GenServer

  alias JoePrices.Boundary.V2.PriceRequest
  alias JoePrices.Boundary.V2.PriceCache.PriceCache
  alias JoePrices.Boundary.V2.PriceCache.PriceCacheEntry
  alias JoePrices.Core.V21.Pair
  alias JoePrices.Utils.Parallel

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
  ## Example

  ```
  {:ok, pid} = JoePrices.Boundary.V2.PairRepository.fetch_process(price_request)
  GenServer.call(pid, :fetch_price)
  ```
  """
  def handle_call(:fetch_price, _from, request = %PriceRequest{}) do
    pair_info =
      PriceCache.get_price(:avalanche_mainnet, request)
      |> maybe_update_cache?(request)

    {:reply, pair_info, request}
  end

  defp maybe_update_cache?({:ok, nil}, request = %PriceRequest{}), do: update_cache(request)
  defp maybe_update_cache?(cache_entry, _request), do: cache_entry

  defp update_cache(request = %PriceRequest{}) do
    %{:token_x => tx, :token_y => ty, :bin_step => bin_step} = request

    case lb_factory_module(request.version).fetch_pairs_for_tokens(
           request.network,
           tx,
           ty,
           bin_step
         ) do
      {:ok, pairs} ->
        [info] = fetch_pairs_info(pairs, request)
        PriceCache.update_prices(request.network, request.version, [info])
        {:ok, PriceCacheEntry.new(info)}

      _ ->
        {:error, "LBFactory contract call error (fetch_pairs_for_tokens)"}
    end
  end

  defp fetch_pairs_info(pairs, request = %PriceRequest{}) do
    pairs
    |> Parallel.pmap(fn pair -> process_pair(pair, request) end)
  end

  defp process_pair({_, @bad_resp_addr, _, _}, _request), do: nil

  defp process_pair({_, addr, _, _}, request = %PriceRequest{}) do
    {:ok, [active_bin]} =
      lb_pair_module(request.version).fetch_active_bin_id(request.network, addr)

    %Pair{
      name: "",
      token_x: request.token_x,
      token_y: request.token_y,
      bin_step: request.bin_step,
      active_bin: active_bin
    }
  end

  @spec init(any) :: {:ok, any}
  def init(args) do
    {:ok, args}
  end

  @spec start_link(PriceRequest.t()) ::
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
      {JoePrices.Registry.V21.PairRepository, request}
    }
  end

  @spec fetch_process(PriceRequest.t()) :: {:error, any} | {:ok, pid()}
  def fetch_process(request = %PriceRequest{}) do
    child =
      DynamicSupervisor.start_child(
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

  @spec lb_factory_module(atom()) :: any()
  defp lb_pair_module(:v20), do: JoePrices.Contracts.V20.LbPair
  defp lb_pair_module(:v21), do: JoePrices.Contracts.V21.LbPair
end
