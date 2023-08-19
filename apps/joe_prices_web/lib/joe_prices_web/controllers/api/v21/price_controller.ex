defmodule JoePricesWeb.Api.V21.PriceController do
  use JoePricesWeb, :controller

  alias JoePrices.Boundary.V21.Cache.PriceCacheEntry
  alias JoePrices.Boundary.V21.PriceRequest

  def index(conn, opts) do
    %{"bin_step" => bin_step, "token_x" => tx, "token_y" => ty} = opts

    {bin_step, _} = Integer.parse(bin_step)

    price_request = %PriceRequest{
      token_x: tx,
      token_y: ty,
      bin_step: bin_step
    }

    case JoePricesV21.get_price(price_request) do
      {:ok, price} -> json(conn, render_price(price))
      {:error, _} -> text(conn, "error")
      price -> json(conn, render_price(price))
    end
  end

  def batch(conn, %{"tokens" => tokens_list} = _opts) do
    parsed_tokens = tokens_list
    |> Enum.map(&parse_token_request/1)

    prices = JoePricesV21.get_prices(parsed_tokens)
    |> render_prices()

    json(conn, prices)
  end

  defp parse_token_request(%{"token_x" => tx, "token_y" => ty, "bin_step" => bs} = _token_request) do
    %PriceRequest{
      token_x: tx,
      token_y: ty,
      bin_step: bs
    }
  end

  defp render_prices(prices) do
    Enum.map(prices, &render_price/1)
  end

  defp render_price(price = %PriceCacheEntry{}) do
    %{
      token_x: price.token_x,
      token_y: price.token_y,
      price: price.price
    }
  end
end
