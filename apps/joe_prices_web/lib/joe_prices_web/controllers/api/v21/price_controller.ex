defmodule JoePricesWeb.Api.V21.PriceController do
  use JoePricesWeb, :controller

  alias JoePrices.Core.V21.Pair
  alias JoePrices.Boundary.V2.PriceRequest

  def index(conn, opts) do
    price_request = parse_token_request(opts)
    price = JoePricesV2.get_price(price_request)
    json(conn, render_price(price))
  end

  def batch(conn, %{"tokens" => tokens_list} = _opts) do
    prices = tokens_list
    |> Enum.map(&parse_token_request/1)
    |> JoePricesV2.get_prices()
    |> render_prices()

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

  defp render_prices(prices) do
    Enum.map(prices, &render_price/1)
  end

  defp render_price({:ok, price} = _ok), do: render_price(price)
  defp render_price({:error, _}), do: %{error: "could not fetch price"}
  defp render_price(%Pair{} = pair) do
    %{
      token_x: pair.token_x,
      token_y: pair.token_y,
      price: pair.price
    }
  end
end
