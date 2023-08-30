defmodule JoePrices.Boundary.V2.PairRepository do
  @moduledoc """
  GenServer definition for a v2 pair repository.

  Each requested pair spawns its own process dynamically.

  Used to serialize requests to the same pair to avoid duped calls when cache is invalid.
  """

  use GenServer

  alias JoePrices.Boundary.V2.PriceRequest
  alias JoePrices.Boundary.V2.PriceComputator
  alias JoePrices.Boundary.V2.PriceCache.PriceCache
  alias JoePrices.Core.V21.Pair

  @bad_resp_addr "0x0000000000000000000000000000000000000000"

  @doc """
  Returns the price for a given pair.
  """
  @spec get_price(PriceRequest.t()) :: Pair.t()
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

  defp update_cache(
    request = %PriceRequest{:token_x => tx, :token_y => ty, :bin_step => bin_step, :network => network, :version => version}
  ) do
    case lb_factory_module(version).fetch_pair_for_tokens(
           network,
           tx,
           ty,
           bin_step
         ) do
      {:ok, [{_, pair_address, _, _}]} ->
        pair_info = fetch_pair_info(pair_address, request)
        PriceCache.update_price(network, version, pair_info)
        {:ok, pair_info}

      _ ->
        {:error, "LBFactory contract call error (fetch_pair_for_tokens)"}
    end
  end

  def fetch_pair_info(@bad_resp_addr, _request), do: nil

  def fetch_pair_info(addr, request = %PriceRequest{}) do
    {:ok, [active_bin]} =
      lb_pair_module(request.version).fetch_active_bin_id(request.network, addr)

    price = PriceComputator.compute_price(request, active_bin)
    [token_x, token_y] = sorted_tokens(request.token_x, request.token_y)

    %Pair{
      name: "",
      token_x: token_x,
      token_y: token_y,
      bin_step: request.bin_step,
      active_bin: active_bin,
      price: price,
      address: addr,
      network: request.network,
      version: request.version
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

  defp sorted_tokens(token_x, token_y) when token_x < token_y, do: [token_x, token_y]
  defp sorted_tokens(token_x, token_y), do: [token_y, token_x]
end
