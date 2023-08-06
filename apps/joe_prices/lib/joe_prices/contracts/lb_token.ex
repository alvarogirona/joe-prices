defmodule JoePrices.Contracts.LbToken do
  use Ethers.Contract,
    abi_file: "priv/abis/LBToken.json"
end
