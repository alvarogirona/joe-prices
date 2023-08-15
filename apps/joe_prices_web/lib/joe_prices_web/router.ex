defmodule JoePricesWeb.Router do
  use JoePricesWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {JoePricesWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", JoePricesWeb do
    scope "/v1" do

    end

    scope "/v2" do

    end

    scope "/v2_1" do
      scope "/prices" do
        get "/:token_x/:token_y/:bin_step", Api.V21.PriceController, :index
        post "/v2_1/batch-prices", Api.V21.PriceController, :batch
      end
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", JoePricesWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:joe_prices_web, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: JoePricesWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
