defmodule Frontend.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FrontendWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:frontend, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Frontend.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Frontend.Finch},
      # Start a worker by calling: Frontend.Worker.start_link(arg)
      # {Frontend.Worker, arg},
      # Start to serve requests, typically the last entry
      FrontendWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Frontend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FrontendWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
