defmodule JoePricesWeb.Api.V21.PriceController do
  use JoePricesWeb, :controller

  alias JoePrices.Boundary.V21.PriceRequest

  def index(conn, opts) do
    %{"bin_step" => bin_step, "token_x" => tx, "token_y" => ty} = opts

    {bin_step, _} = Integer.parse(bin_step)

    price_request = %PriceRequest{
      token_x_address: tx,
      token_y_address: ty,
      bin_step: bin_step
    }

    [price] = JoePricesV21.get_price(price_request)

    IO.puts(">>>>")
    IO.inspect(price)
    IO.puts(">>>>")

    IO.inspect(price.active_bin)
    IO.inspect(price.bin_step)

    json(conn, %{
      token_x: price.token_x_address,
      token_y: price.token_y_address,
      price: JoePrices.Core.V21.Bin.get_price_from_id(price.active_bin, price.bin_step)
    })
  end
end
