defmodule MaggotEngine do
  @moduledoc """
  Documentation for `MaggotEngine`.
  """
  use DynamicSupervisor

  @impl true
  def init(_init_arg), do:   DynamicSupervisor.init(strategy: :one_for_one)

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def open_new_room(name) do
    DynamicSupervisor.start_child(__MODULE__, MaggotEngine.Game.child_spec(name))
  end

  def close_room(name) do
    pid = Process.whereis(name)
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  def workers_lobby_extended(), do: DynamicSupervisor.which_children(__MODULE__)


  def workers_lobby(), do: DynamicSupervisor.count_children(__MODULE__)
end
