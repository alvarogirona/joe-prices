defmodule JoePrices.Contracts.V21.LbPair do
  alias JoePrices.Core.V21.Bin
  alias JoePrices.Core.V21.Pair
  alias JoePrices.Boundary.Token.TokenInfoFetcher
  alias JoePrices.Core.Network
  alias JoePrices.Utils.Parallel

  @type network_name() :: :arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet

  @minimum_liquidity_threshold 10

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

  @doc """
  Checks if a pair has enough liquidity by looking in +-5 bins of its active bin, getting their reserves as checking if the total
  amount in dolars is > 10$

  ## Example
    iex> JoePrices.Contracts.V21.LbPair.pair_has_enough_reserves_around_active_bin?(
      "0x152b9d0fdc40c096757f570a51e494bd4b943e50",
      "0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7",
      "0xd9fa522f5bc6cfa40211944f2c8da785773ad99d",
      8419521,
      :avalanche_mainnet,
      10,
      27_228,
      10.38
    )
  """
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

  @doc """
  ## Example
  Example with btc.e/avax pair:

    iex> JoePrices.Contracts.V21.LbPair.get_reserves_around_active_bin(
      "0x152b9d0fdc40c096757f570a51e494bd4b943e50",
      "0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7",
      "0xd9fa522f5bc6cfa40211944f2c8da785773ad99d",
      8419521,
      :avalanche_mainnet
    )
  """
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
    # Enum.to_list(active_bin - 5..active_bin)
  end
end

# 0xd446eb1660f766d533beceef890df7a69d26f7d1
