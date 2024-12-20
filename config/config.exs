# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Configure Mix tasks and generators
config :joe_prices,
  ecto_repos: [JoePrices.Repo]

config :joe_prices,
  avax_rpc: System.get_env("AVAX_RPC_URL") || "https://rpc.ankr.com/avalanche",
  arbitrum_rpc: System.get_env("ARB_RPC_URL") || "https://rpc.ankr.com/arbitrum",
  bsc_rpc: System.get_env("BSC_RPC_URL") || "https://rpc.ankr.com/bsc"

config :joe_prices_web,
  ecto_repos: [JoePrices.Repo],
  generators: [context_app: :joe_prices]

# Configures the endpoint
config :joe_prices_web, JoePricesWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: JoePricesWeb.ErrorHTML, json: JoePricesWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: JoePrices.PubSub,
  live_view: [signing_salt: "+GMOvF6T"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/joe_prices_web/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.7",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/joe_prices_web/assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ethers,
  rpc_client: Ethereumex.HttpClient, # Defaults to: Ethereumex.HttpClient
  keccak_module: ExKeccak, # Defaults to: ExKeccak
  json_module: Jason # Defaults to: Jason

# If using Ethereumex, you need to specify a JSON-RPC server url here
config :ethereumex,
  http_headers: [{"Content-Type", "application/json"}]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
