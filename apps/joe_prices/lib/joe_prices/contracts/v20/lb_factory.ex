defmodule JoePrices.Contracts.V20.LbFactory do
  use Ethers.Contract,
    abi_file: "priv/abis/v20/LBFactory.json",
    default_address: "0x6E77932A92582f504FF6c4BdbCef7Da6c198aEEf"

  alias JoePrices.Core.Network

  @type network :: :arbitrum_mainnet | :avalanche_mainnet | :bsc_mainnet
  @type pair_info :: {non_neg_integer, binary, boolean, boolean}
  @type error_message :: {:error, binary}
  @type success_result ::
          {:ok,
           binary | [pair_info] | %{data: binary, selector: ABI.FunctionSelector.t(), to: binary}}

  @doc """
  Fetches all pairs for the given tokens and bin step for v2.0.

  ## Example

  iex> JoePrices.Contracts.V20.LbFactory.fetch_pair_for_tokens(:avalanche_mainnet, "0x9702230a8ea53601f5cd2dc00fdbc13d4df4a8c7", "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e", 1)

    {:ok, [{1, "0x1d7a1a79e2b4ef88d2323f3845246d24a3c20f1d", true, false}]}
  """
  @spec fetch_pair_for_tokens(network, binary, binary, non_neg_integer) :: error_message | success_result
  def fetch_pair_for_tokens(network, token_x, token_y, bin_step) do
    opts = Network.opts_for_call(network, contract_for_network(network))

    case __MODULE__.get_lb_pair_information(
           token_x,
           token_y,
           bin_step,
           opts
         ) do
      {:ok, pairs} -> {:ok, pairs}
      {:error, _} -> {:error, "Error getting pairs for tokens"}
    end
  end

  defp contract_for_network(:avalanche_mainnet), do: "0x6E77932A92582f504FF6c4BdbCef7Da6c198aEEf"
  defp contract_for_network(:arbitrum_mainnet), do: "0x1886D09C9Ade0c5DB822D85D21678Db67B6c2982"
  defp contract_for_network(:bsc_mainnet), do: "0x43646A8e839B2f2766392C1BF8f60F6e587B6960"
end
