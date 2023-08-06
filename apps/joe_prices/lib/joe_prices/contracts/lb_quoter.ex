defmodule JoePrices.Contracts.LbQuoter do
  use Ethers.Contract,
    abi_file: "priv/abis/LBQuoter.json"
end
