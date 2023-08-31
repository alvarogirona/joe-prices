defmodule JoePrices.Contracts.V20.LbPair do
  use Ethers.Contract,
    abi_file: "priv/abis/v20/LBPair.json"

  alias JoePrices.Core.Network
  alias JoePrices.Boundary.Token.TokenInfoFetcher
  alias JoePrices.Utils.Parallel

  @type available_networks :: :arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet

  @doc """
  Fetches active bin for a given pair.

  ## Parameters

  - `network` (chain): chain to make the request (i.e: `:avalanche_mainnet`)
  - `pair_address`: address of the pair

  ## Example

  ```
  iex> JoePrices.Contracts.V20.LbPair.fetch_active_bin(:avalanche_mainnet, "0x1d7a1a79e2b4ef88d2323f3845246d24a3c20f1d")
  ```
  """
  @spec fetch_active_bin_id(atom(), String.t()) :: {:error, any} | {:ok, any}
  def fetch_active_bin_id(network, pair_address) do
    opts = Network.opts_for_call(network, pair_address)

    case __MODULE__.get_reserves_and_id(opts) do
      {:ok, [_, _, active_bin_id]} -> {:ok, [active_bin_id]}
      _ -> {:error, :undefined_error}
    end
  end

  @spec fetch_bin_reserves(String.t(), non_neg_integer(), available_networks()) :: any()
  def fetch_bin_reserves(pair_address, bin_id, network) do
    opts = Network.opts_for_call(network, pair_address)

    __MODULE__.get_bin(bin_id, opts)
  end

  def pair_has_enough_reserves_around_active_bin?(
    token_x,
    token_y,
    address,
    active_bin,
    network,
    price_x_in_dollars,
    price_y_in_dollars
  ) do
    [reserves_below, reserves_above] = get_reserves_around_active_bin(token_x, token_y, address, active_bin, network)
    |> Enum.map(&Enum.sum/1)

    (reserves_below * price_x_in_dollars) + (reserves_above * price_y_in_dollars) > @minimum_liquidity_threshold
  end

  def get_reserves_around_active_bin(token_x, token_y, address, active_bin, network) do
    opts = Network.opts_for_call(network, address)

    token_x_decimals = TokenInfoFetcher.get_decimals_for_token(token_x)
    token_y_decimals = TokenInfoFetcher.get_decimals_for_token(token_y)

    reserves_above = Enum.to_list(active_bin + 1..active_bin + 5)
      |> Parallel.pmap(fn bin_id ->
        {:ok, [reserves, _]} = __MODULE__.fetch_bin_reserves(address, bin_id, network)

        reserves
      end)
      |> Enum.map(fn res -> res * :math.pow(10, -token_x_decimals) end)

    reserves_below = Enum.to_list(active_bin - 5..active_bin - 1)
      |> Parallel.pmap(fn bin_id ->
        {:ok, [_, reserves]} = __MODULE__.fetch_bin_reserves(address, bin_id, network)
        reserves
      end)
      |> Enum.map(fn res -> res * :math.pow(10, -token_y_decimals) end)

    [reserves_below, reserves_above]
  end

  @spec fetch_bin_step(available_networks(), String.t()) :: {:error, any} | {:ok, non_neg_integer}
  def fetch_bin_step(network, contract_address) do
    opts = Network.opts_for_call(network, contract_address)

    case __MODULE__.fee_parameters(opts) do
      {:ok, [{bin_step, _, _, _, _, _, _, _, _, _, _, _} | _]} -> {:ok, bin_step}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :unknown}
    end
  end

  @doc """

  ## Example
  ```
  iex> JoePrices.Contracts.V20.LbPair.fetch_tokens(:avalanche_mainnet, "0xD446eb1660F766d533BeCeEf890Df7A69d26f7d1")
  [
    ["0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7"],
    ["0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e"]
  ]
  ```
  """
  @spec fetch_tokens(:arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet, binary) ::
          [String.t() | String.t()]
          | {:error, any}
  def fetch_tokens(network, contract_address) do
    opts = Network.opts_for_call(network, contract_address)

    with {:ok, [token_x]} <- __MODULE__.token_x(opts),
         {:ok, [token_y]} <- __MODULE__.token_y(opts) do
      [token_x, token_y]
    end
  end
end
