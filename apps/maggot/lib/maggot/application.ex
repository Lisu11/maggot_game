defmodule Maggot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Maggot.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Maggot.PubSub}
      # Start a worker by calling: Maggot.Worker.start_link(arg)
      # {Maggot.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Maggot.Supervisor)
  end
end
