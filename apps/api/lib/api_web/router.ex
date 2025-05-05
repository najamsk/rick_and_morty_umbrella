defmodule ApiWeb.Router do
  use ApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ApiWeb do
    pipe_through :api

    get "/characters/search",
        CharacterController,
        :search

    get "/characters", CharacterController, :index
    get "/plots/:ids", CharacterController, :get_plots
    get "/search_options", CharacterController, :search_options
    get "/characters/:id", CharacterController, :show
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:api, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: ApiWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end

    # Catch-all for ignored dev-only paths
    scope "/phoenix", ApiAppWeb do
      match :*, "/*path", FallbackController, :not_found
    end
  end
end
