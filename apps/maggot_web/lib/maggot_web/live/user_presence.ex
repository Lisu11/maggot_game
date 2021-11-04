defmodule MaggotWeb.UserPresence do
  use GenServer
  alias MaggotWeb.{Endpoint, Presence}

  def init(_init_arg) do
    {:ok, nil}
  end

  def handle_cast({:track, topic, pid, username}, state) do
    Presence.track(pid, topic, username, %{})
    {:noreply, state}
  end

  def start_link(init) do
    GenServer.start_link(__MODULE__, init, name: __MODULE__) # only works for one but every view shoud have one
  end

  def track(topic, username) do
    GenServer.cast(__MODULE__, {:track, topic,  self(), username})
  end
end
