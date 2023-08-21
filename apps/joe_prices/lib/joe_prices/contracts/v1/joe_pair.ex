defmodule JoePrices.Contracts.V1.JoePair do
  use Ethers.Contract,
    abi_file: "priv/abis/v1/pair.json"
end
