defmodule JoePrices.Contracts.V20.LbFactory do
  use Ethers.Contract,
    abi_file: "priv/abis/v20/LBFactory.json",
    default_address: "0x6E77932A92582f504FF6c4BdbCef7Da6c198aEEf"



    defp contract_for_network(:avalanche_mainner), do: "0x6E77932A92582f504FF6c4BdbCef7Da6c198aEEf"
    defp contract_for_network(:arbitrum_mainnet), do: "0x1886D09C9Ade0c5DB822D85D21678Db67B6c2982"
    defp contract_for_network(:bsc), do: "0x43646A8e839B2f2766392C1BF8f60F6e587B6960"
end
