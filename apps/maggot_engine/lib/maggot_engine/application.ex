defmodule MaggotEngine.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: MaggotEngine.Worker.start_link(arg)
      # {MaggotEngine.Worker, arg}
      # :poolboy.child_spec(:worker, poolboy_config())
      {DynamicSupervisor, strategy: :one_for_one, name: MaggotEngine}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MaggotEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp poolboy_config do
    [
      name: {:local, :worker},
      worker_module: MaggotEngine.Game,
      size: 1,
      max_overflow: 2
    ]
  end

end
