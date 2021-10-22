defmodule MaggotWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      MaggotWeb.Telemetry,
      # Start the Endpoint (http/https)
      MaggotWeb.Endpoint
      # Start a worker by calling: MaggotWeb.Worker.start_link(arg)
      # {MaggotWeb.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MaggotWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MaggotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
