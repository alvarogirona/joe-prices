defmodule JoePrices.Repo do
  use Ecto.Repo,
    otp_app: :joe_prices,
    adapter: Ecto.Adapters.Postgres
end
