defmodule MaggotEngine.Game do
  alias MaggotEngine.Game.{State}
  use GenServer
  @width 100
  @height 100
  @framerate 10

  @impl true
  def init(_) do
    schedule_ticks()
    { :ok, State.new( @width, @height) }
  end

  @impl true
  def handle_call(:add_player, {from, _}, state) do
    { :reply, :ok, State.add_player(state, from) }
  end

  @impl true
  def handle_info(:tick, state) do
    { :noreply, transform_state_and_notify_players(state) }
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def add_player(pid) do
    GenServer.call(pid, :add_player)
  end

  defp transform_state_and_notify_players(state) do
    state
    # |> State.update_bugs() # uncomment this
      |> State.move_and_notify()
  end

  defp schedule_ticks() do
    pid = IO.inspect(self())
    :timer.apply_interval(Integer.floor_div(1000, @framerate), __MODULE__, :send_tick, [pid])
  end
  def send_tick(pid), do: send(pid, :tick)
end
