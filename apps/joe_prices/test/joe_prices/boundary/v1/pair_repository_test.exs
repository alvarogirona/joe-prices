defmodule JoePrices.Boundary.V1.PairRepositoryTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias JoePrices.Boundary.V1.{PairRepository, PriceRequest}

  test "fetch_process returns the same pid for requests with the same token addresses in different orders" do
    request1 = %PriceRequest{
      base_asset: "0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd",
      quote_asset: "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e"
    }

    request2 = %PriceRequest{
      base_asset: "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e",
      quote_asset: "0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd"
    }

    {:ok, pid1} = PairRepository.fetch_process(request1)
    {:ok, pid2} = PairRepository.fetch_process(request2)

    assert pid1 == pid2
  end

  test "fetch_process returns different pids for requests with different token addresses" do
    request1 = %PriceRequest{
      base_asset: "0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd",
      quote_asset: "0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e"
    }

    request2 = %PriceRequest{
      base_asset: "0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd",
      quote_asset: "0xother_address"
    }

    {:ok, pid1} = PairRepository.fetch_process(request1)
    {:ok, pid2} = PairRepository.fetch_process(request2)

    refute pid1 == pid2
  end
end
