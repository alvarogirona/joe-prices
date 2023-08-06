import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :joe_prices, JoePrices.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "joe_prices_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :joe_prices_web, JoePricesWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "T1Uqr6hPH9kNB3B1X0CYz0VdzDmg+c3wnKs6L0G/IAZzaCEH83oxpdYKvMM2GBAC",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# In test we don't send emails.
config :joe_prices, JoePrices.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
