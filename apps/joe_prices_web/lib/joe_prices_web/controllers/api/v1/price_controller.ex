defmodule JoePricesWeb.Api.V1.PriceController do
  use JoePricesWeb, :controller

  alias JoePrices.Contracts.V1.JoePair
  alias JoePrices.Boundary.V1.PriceRequest

  def index(conn, %{"base_asset" => base_asset, "quote_asset" => quote_asset} = _params) do
    price_request = %PriceRequest{
      base_asset: base_asset,
      quote_asset: quote_asset
    }

    {:ok, joe_pair} = JoePricesV1.get_price(price_request)

    json(conn, %{
      base_asset: base_asset,
      quote_asset: quote_asset,
      price: joe_pair.price
    })
  end

  def batch(conn, %{"tokens" => tokens_list} = _opts) do
    parsed_requests = tokens_list
    |> Enum.map(&parse_token_request/1)

    pairs = JoePricesV1.get_prices(parsed_requests)
    |> render_pairs(tokens_list)

    json(conn, pairs)
  end

  defp parse_token_request(%{"base_asset" => base_asset, "quote_asset" => quote_asset} = _req) do
    %PriceRequest{
      base_asset: base_asset,
      quote_asset: quote_asset
    }
  end

  @spec render_pairs(list(JoePair.t()), list()) :: any()
  defp render_pairs(pairs, requests) do
    Enum.map(pairs, fn pair_response ->
      case pair_response do
        {:ok, pair} -> render_ok_pair(pair)
      end
    end)
  end

  defp render_ok_pair(pair) do
    %{
      base_asset: pair.token_x,
      quote_asset: pair.token_y,
      price: pair.price,
      inverse_price: pair.inverse_price
    }
  end
end
