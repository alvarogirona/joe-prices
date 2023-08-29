defmodule JoePrices.Contracts.V21.LbPair do
  alias JoePrices.Core.V21.Pair
  alias JoePrices.Boundary.Token.TokenInfoFetcher
  alias JoePrices.Core.Network
  alias JoePrices.Utils.Parallel

  @type network_name() :: :arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet

  use Ethers.Contract,
    abi_file: "priv/abis/v21/LBPair.json",
    default_address: "0x2f1da4bafd5f2508ec2e2e425036063a374993b6"

  @doc """
  ## Example
    iex> JoePrices.Contracts.V21.LbPair.fetch_active_bin_id(:avalanche_mainnet, "0x2f1da4bafd5f2508ec2e2e425036063a374993b6")
    {:ok, [8112282]}
  """
  @spec fetch_active_bin_id(network_name(), String.t()) :: {:error, any} | {:ok, any}
  def fetch_active_bin_id(network, pair_contract) do
    opts = Network.opts_for_call(network, pair_contract)

    JoePrices.Contracts.V21.LbPair.get_active_id(opts)
  end

  @doc """
  ## Example
    iex> JoePrices.Contracts.V21.LbPair.fetch_bin_step(:avalanche_mainnet, "0x2f1da4bafd5f2508ec2e2e425036063a374993b6")
    {:ok, 1}
  """
  @spec fetch_bin_step(network_name(), String.t()) :: {:error, any} | {:ok, non_neg_integer}
  def fetch_bin_step(network, contract_address) do
    opts = Network.opts_for_call(network, contract_address)

    case __MODULE__.get_bin_step(opts) do
      {:ok, [bin_step]} -> {:ok, bin_step}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :unknown}
    end
  end

  @doc """
  ## Example

    iex> JoePrices.Contracts.V21.LbPair.fetch_tokens(:avalanche_mainnet, "0xD446eb1660F766d533BeCeEf890Df7A69d26f7d1")
    [
      ["0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7"],
      ["0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e"]
    ]
  """
  @spec fetch_tokens(:arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet, binary) ::
          [String.t() | String.t()]
          | {:error, any}
  def fetch_tokens(network, contract_address) do
    opts = Network.opts_for_call(network, contract_address)

    with {:ok, [token_x]} <- JoePrices.Contracts.V21.LbPair.get_token_x(opts),
         {:ok, [token_y]} <- JoePrices.Contracts.V21.LbPair.get_token_y(opts) do
      [token_x, token_y]
    end
  end

  def has_enough_liquidity() do

  end

  @doc"""
  ## Example

  ```
  iex> JoePrices.Contracts.V21.LbPair.fetch_bin_reserves("0xD446eb1660F766d533BeCeEf890Df7A69d26f7d1", 8375933, :avalanche_mainnet)
  ```
  """
  @spec fetch_bin_reserves(String.t(), non_neg_integer(), network_name()) :: any()
  def fetch_bin_reserves(pair_address, bin_id, network \\ :avalanche_mainnet) do
    opts = Network.opts_for_call(network, pair_address)

    __MODULE__.get_bin(bin_id, opts)
  end

  def pair_has_enough_reserves_around_active_bin?(%Pair{} = pair, price_in_dollars) do
    [above, below] = get_reserves_around_active_bin(pair)
  end

  @doc """
  ## Example
    iex> btc_avax_pair = %JoePrices.Core.V21.Pair{
      address: "0xd9fa522f5bc6cfa40211944f2c8da785773ad99d",
      network: :avalanche_mainnet,
      version: :v21,
      name: "",
      token_x: "0x152b9d0fdc40c096757f570a51e494bd4b943e50",
      token_y: "0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7",
      bin_step: 10,
      active_bin: 8419498,
      price: 27621.785201428967
    }
    iex> JoePrices.Contracts.V21.LbPair.get_reserves_around_active_bin(btc_avax_pair)
  """
  def get_reserves_around_active_bin(%Pair{active_bin: active_bin} = pair) do
    opts = Network.opts_for_call(pair.network, pair.address)

    token_x_decimals = TokenInfoFetcher.get_decimals_for_token(pair.token_x)
    token_y_decimals = TokenInfoFetcher.get_decimals_for_token(pair.token_y)

    reserves_above = Enum.to_list(active_bin + 1..active_bin + 5)
      |> Parallel.pmap(fn bin_id ->
        {:ok, reserves} = __MODULE__.fetch_bin_reserves(pair.address, bin_id, pair.network)
        reserves
      end)

    reserves_below = Enum.to_list(active_bin - 5..active_bin - 1)
      |> Parallel.pmap(fn bin_id ->
        {:ok, reserves} = __MODULE__.fetch_bin_reserves(pair.address, bin_id, pair.network)
        reserves
      end)

    {reserves_below, reserves_above}
    # Enum.to_list(active_bin - 5..active_bin)
  end
end

# 0xd446eb1660f766d533beceef890df7a69d26f7d1
