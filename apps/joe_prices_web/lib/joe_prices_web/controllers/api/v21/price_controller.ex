defmodule JoePricesWeb.Api.V21.PriceController do
  use JoePricesWeb, :controller

  alias JoePrices.Core.V2.Pair
  alias JoePrices.Boundary.V2.PriceRequest

  def index(conn, opts) do
    price_request = parse_token_request(opts)
    price = JoePricesV2.get_price(price_request)
    json(conn, render_price(price, price_request))
  end

  def batch(conn, %{"tokens" => tokens_list} = _opts) do
    requests = tokens_list
    |> Enum.map(&parse_token_request/1)

    prices = JoePricesV2.get_prices(requests)
    |> render_prices(requests)

    json(conn, prices)
  end

  defp parse_token_request(%{"token_x" => tx, "token_y" => ty, "bin_step" => bs} = _token_request) do
    bin_step = parse_bin_step(bs)

    %PriceRequest{
      token_x: tx,
      token_y: ty,
      bin_step: bin_step,
      version: :v21
    }
  end

  defp parse_bin_step(bs) when is_binary(bs), do: Integer.parse(bs) |> elem(0)
  defp parse_bin_step(bs) when is_integer(bs), do: bs

  defp render_prices(prices, requests) do
    Enum.zip(prices, requests)
    |> Enum.map(fn {price, request} -> render_price(price, request) end)
  end

  defp render_price({:ok, price} = _ok, request = %PriceRequest{}), do: render_price(price, request)
  defp render_price({:error, _}, request = %PriceRequest{}), do: %{error: "could not fetch price"}
  defp render_price(%Pair{} = pair, request = %PriceRequest{}) do
    price = if pair.token_x == request.token_x do
      pair.price
    else
      1 / pair.price
    end

    %{
      base_asset: request.token_x,
      quote_asset: request.token_y,
      token_x: pair.token_x,
      token_y: pair.token_y,
      price: price
    }
  end
end
