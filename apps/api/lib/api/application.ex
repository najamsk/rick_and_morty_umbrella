defmodule Api.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  @auto_fetch_data Application.compile_env(:api, :auto_fetch_data, false)

  @impl true
  def start(_type, _args) do
    # dbg(@auto_fetch_data)

    if @auto_fetch_data do
      Task.start(fn ->
        Api.Seeder.Seeder.fetch_and_save_characters()
        Api.Seeder.Seeder.fetch_and_save_episodes()
        # Api.RickAndMortyFetcher.fetch_and_save_characters()
        # Api.RickAndMortyEpisodeFetcher.fetch_and_save_episodes()
        Api.Data.Store.load_data()
      end)
    else
      Api.Data.Store.load_data()
    end

    children = [
      ApiWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:api, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Api.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Api.Finch},
      # Start a worker by calling: Api.Worker.start_link(arg)
      # {Api.Worker, arg},
      # Start to serve requests, typically the last entry
      ApiWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Api.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
