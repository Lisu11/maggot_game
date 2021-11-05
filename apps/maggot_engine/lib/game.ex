defmodule MaggotEngine.Game do
  alias MaggotEngine.Game.{State, Maggot}
  use GenServer
  @width 250
  @height 150
  @framerate 10

  @impl true
  def init(_) do
    schedule_ticks()
    { :ok, State.new( @width, @height) }
  end

  @impl true
  def handle_cast({:subscribe, from}, state) do
    { :noreply, State.add_stopped_player(state, from) }
  end
  @impl true
  def handle_cast({:unsubscribe, from}, state) do
    { :noreply, State.remove_stopped_player(state, from) }
  end

  @impl true
  def handle_cast({:move, direction, from}, state) do
    {:noreply, State.change_direction(state, from, direction)}
  end
  @impl true
  def handle_call(:join_game, {from, _}, state) do
    case State.add_player(state, from) do
      {:ok, state} ->
        { :reply, :ok, state }
      {:error, reason} ->
        { :reply, {:error, reason}, state}
    end
  end


  @impl true
  def handle_info(:tick, state) do
    { :noreply, transform_state_and_notify_players(state) }
  end


  def start_link(name) do
    GenServer.start_link(__MODULE__, nil, name: name)
  end

  def subscribe(room_name) do
    pid = Process.whereis(room_name)
    GenServer.cast(pid, {:subscribe, self()})
  end

  def unsubscribe(room_name) do
    pid = Process.whereis(room_name)
    GenServer.cast(pid, {:unsubscribe, self()})
  end

  def join_game(room_name) do
    pid = Process.whereis(room_name)
    GenServer.call(pid, :join_game)
  end

  # def leave_game(room_name) do
  #   pid = Process.whereis(room_name)
  #   GenServer.call(pid, :leave_game)
  # end

  def change_direction(room_name, direction) when direction in [:n, :e, :s, :w] do
    pid = Process.whereis(room_name)

    from = self()
    GenServer.cast(pid, {:move, direction, from})
  end

  defp transform_state_and_notify_players(state) do
    state
      |> State.update_counter()
      |> State.init_changes()
      |> State.step()
      |> State.detect_next_step_collisions()
      |> State.add_rest_of_the_stopped_maggot_to_changes()
      |> State.clear_stopped_players()
      |> State.update_board()
      |> State.update_bugs() # needs to be called AFTER update_board
      |> State.notify_players()

  end

  defp schedule_ticks() do
    pid = IO.inspect(self())
    :timer.apply_interval(Integer.floor_div(1000, @framerate), __MODULE__, :send_tick, [pid])
  end
  def send_tick(pid), do: send(pid, :tick)
end
