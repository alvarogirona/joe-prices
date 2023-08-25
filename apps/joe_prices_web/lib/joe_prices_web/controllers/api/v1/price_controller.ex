defmodule JoePricesWeb.Api.V1.PriceController do
  use JoePricesWeb, :controller

  alias JoePrices.Contracts.V1.JoePair
  alias JoePrices.Boundary.V1.PriceRequest

  def index(conn, params = %{"base_asset" => _, "quote_asset" => _}) do
    price_request = parse_token_request(params)

    {:ok, joe_pair} = JoePricesV1.get_price(price_request)

    json(conn, %{
      base_asset: price_request.base_asset,
      quote_asset: price_request.quote_asset,
      price: joe_pair.price
    })
  end

  def batch(conn, %{"tokens" => tokens_list}) do
    pairs = tokens_list
    |> Enum.map(&parse_token_request/1)
    |> JoePricesV1.get_prices()
    |> render_pairs()

    json(conn, pairs)
  end

  defp parse_token_request(%{"base_asset" => base_asset, "quote_asset" => quote_asset}) do
    %PriceRequest{
      base_asset: base_asset,
      quote_asset: quote_asset
    }
  end

  @spec render_pairs(list(JoePair.t())) :: any()
  defp render_pairs(pairs) do
    Enum.map(pairs, fn
      {:ok, pair} -> render_ok_pair(pair)
      {:error, _} -> %{error: "could not fetch price"}
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
