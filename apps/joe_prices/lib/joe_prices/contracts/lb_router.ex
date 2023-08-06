defmodule JoePrices.Contracts.LbRouter do
  use Ethers.Contract,
    abi_file: "priv/abis/LBRouter.json"
end
