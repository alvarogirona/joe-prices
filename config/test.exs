import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
# We don't run a server during test. If one is required,
# you can enable the server option below.
config :joe_prices_web, JoePricesWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "T1Uqr6hPH9kNB3B1X0CYz0VdzDmg+c3wnKs6L0G/IAZzaCEH83oxpdYKvMM2GBAC",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
