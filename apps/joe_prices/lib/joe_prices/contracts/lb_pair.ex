defmodule JoePrices.Contracts.LbPair do
  # 0x4b9bfeD1dD4E6780454b2B02213788f31FfBA74a
 use Ethers.Contract,
    abi_file: "priv/abis/LBPair.json",
    default_address: "0x4b9bfeD1dD4E6780454b2B02213788f31FfBA74a"
end
