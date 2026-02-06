defmodule NotesAppGcloudWeb.Router do
  use NotesAppGcloudWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api" do
    pipe_through :api

    get "/health", NotesAppGcloudWeb.HealthController, :index

    forward "/graphql", Absinthe.Plug, schema: NotesAppGcloudWeb.Schema

    if Application.compile_env(:notes_app_gcloud, :dev_routes) do
      forward "/graphiql", Absinthe.Plug.GraphiQL, schema: NotesAppGcloudWeb.Schema, interface: :simple
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:notes_app_gcloud, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: NotesAppGcloudWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
