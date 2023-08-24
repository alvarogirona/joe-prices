defmodule JoePricesV1 do
  alias JoePrices.Boundary.V1.PriceRequest
  alias JoePrices.Boundary.V1.PairRepository
  alias JoePrices.Contracts.V1.JoePair
  alias JoePrices.Utils.Parallel

  @spec get_price(PriceRequest.t()) :: JoePair.t()
  def get_price(%PriceRequest{} = request) do
    PairRepository.get_price(request)
  end

  @spec get_prices(list(PriceRequest.t())) :: list(JoePair.t())
  def get_prices(requests) do
    requests
    |> Parallel.pmap(&PairRepository.get_price/1)
  end
end
