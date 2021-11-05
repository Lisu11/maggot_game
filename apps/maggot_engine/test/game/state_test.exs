defmodule MaggotEngineTest.StateTest do
  use ExUnit.Case, async: true

  alias MaggotEngine.Game.{Changes, Board, Maggot}
  alias  MaggotEngine.Game.State
  require Logger

  setup_all do
      h = :rand.uniform(100)
      w = :rand.uniform(100)
      new =
        %{players: %{},
          stopped_players: [],
          board: Board.new(w, h),
          changes: gen_random_changes(w, h),
          counter: 0}



    [state: new, changes: new.changes]
  end

  describe "new/1" do
    test "returns an empty state" do
      h = :rand.uniform(100)
      w = :rand.uniform(100)
      new = State.new(w, h)
      empty =
        %{ players: %{},
           stopped_players: [],
           board: Board.new(w, h),
           changes: Changes.empty(),
           counter: 0}
      assert new === empty
    end
  end

  describe "update_counter/1" do
    @bugs_freq 10 # use Constants from deps instead

    test "counter should be increased when value is less than @bugs_freq",
      %{state: state} do
        counter = :rand.uniform(@bugs_freq - 1)
        state = %{state | counter: counter}
        up_state = State.update_counter(state)
        assert up_state.counter == counter + 1
    end

    test "counter should reset to zero when value is equal @bugs_freq",
      %{state: state} do
        state = %{state | counter: @bugs_freq}
        up_state = State.update_counter(state)
        assert up_state.counter == 0
    end

  end

  describe "update_board/1" do

    test "updated board should contain all added fields from changes",
      %{state: state, changes: changes} do
        up_state = State.update_board(state)

        for {point, what} <- changes.+ do
          assert up_state.board.coords[point] == what
        end
    end

    test "updated board must not contain any subtracted field unless it is also in added fields",
      %{state: state, changes: changes} do
        up_state = State.update_board(state)

        for {point, _what} <- changes.- do
          if point in Map.keys(changes.+) do
            assert up_state.board.coords[point] == changes.+[point]
          else
            assert up_state.board.coords[point] == nil
          end
        end
    end

  end

  describe "add_stopped_player/2" do

    test "new stopped player should be added",
      %{state: state} do
      pid = spawn(fn -> :new_process end)
      up_state = State.add_stopped_player(state, pid)

      assert pid in up_state.stopped_players
    end

  end

  describe "add_player/2" do
    setup %{state: state} do
      pids = Process.list()
      {active, stopped} =
        Enum.split(pids, Integer.floor_div(Enum.count(pids), 2))
      maggots = for _ <- 1..Enum.count(active) do
        x = :rand.uniform(state.board.width)
        y = :rand.uniform(state.board.height)
        Maggot.new!({x,y}, fn _ -> true end)
      end
      active = Map.new(Enum.zip(active, maggots))

      [state: %{state | stopped_players: stopped, players: active}]
    end

    test "should return error when add_player is called for unsubscribed/stopped pid",
      %{state: state} do
        pid = spawn(fn -> :new_process end)

        assert pid not in state.stopped_players
        {:error, :subscribe_first} = State.add_player(state, pid)
    end

    test "should return move player from stopped_players to players when add_player is called for subscribed pid",
      %{state: state} do
        pid = spawn(fn -> :new_process end)

        subscribed_state = State.add_stopped_player(state, pid)

        assert pid not in Map.keys(subscribed_state.players)
        assert pid in subscribed_state.stopped_players

        {:ok, up_state} = State.add_player(subscribed_state, pid)

        assert pid not in up_state.stopped_players
        assert pid in Map.keys(up_state.players)
    end

    test "should assign added player a new random maggot",
      %{state: state} do
        pid = self()
        up_state =
          state
            |> State.add_stopped_player(pid)
            |> State.add_player(pid)
            |> elem(1)

        %Maggot{} = up_state.players[pid]
    end

  end

  describe "change_direction/3" do
    test "pass" do
      # TODO
      IO.puts(:IMPLEMENT_ME)
    end

  end
  describe "update_bugs/1" do
    setup %{state: state} do
      # update_bugs needs to be called AFTER update_board
      # data in board and in changes need to be already synchronized
      state = State.update_board(state)
      [state: state]
    end

    test "for non-zero counter should return state unchanged",
      %{state: state} do
        state = %{state | counter: :rand.uniform(100)}
        assert State.update_bugs(state) === state
    end

    test "when counter in state is zero new bug should appear in changes as well as in board",
      %{state: state} do
        up_state = State.update_bugs(state)

        assert state.changes.- === up_state.changes.-
        assert state.changes.stops === up_state.changes.stops

        assert state.changes.+ !== up_state.changes.+
        [{new_bug, :bug}] =
          up_state.changes.+
          |> Map.to_list()
          |> Kernel.--(Map.to_list(state.changes.+))

        assert state.board.coords[new_bug] == nil
        assert up_state.board.coords[new_bug] == :bug
    end

    test "when counter in state is zero nothing except board and changes should mutate",
      %{state: state} do
        up_state = State.update_bugs(state)
        for key <- Map.keys(state),
          key not in [:changes, :board] do
            assert up_state[key] === state[key]
        end
    end

  end

  describe "clear_stopped_players/1" do
    test "when nothing is stopped in changes then state stay unchanged",
      %{state: state} do
      up_state = State.clear_stopped_players(state)

      assert up_state === state
    end

    test "when stops in changes is nonempty move appropriate active players to stopped_players",
      %{state: state} do
        IO.puts(:IMPLEMENT_ME)
        # changes = Changes.merge(state.changes, Changes.new())
        #  state = %{state | changes: }

    end
  end

  describe "init_changes/1" do

    test "should put empty changes into state", %{state: state} do
      up_state = State.init_changes(state)

      assert up_state.changes == Changes.empty()
    end
  end


  describe "notify_players/1" do

    setup %{state: state} do
      maggots = for _ <- 1..10 do
        x = :rand.uniform(state.board.width)
        y = :rand.uniform(state.board.height)
        Maggot.new!({x,y}, fn _ -> true end)
      end

      asserter = fn ->
        receive do
          {:change, changes} ->
            assert changes === state.changes
          anything_else ->
            Logger.error(inspect(anything_else))
            assert false
          after
            10_000 ->
              IO.puts(:stderr, "No message in 10 seconds")
              assert false
        end
      end

      [state: state, maggots10: maggots, asserter: asserter]
    end

    test "state should be left unchanged", %{state: state} do
      up_state = State.notify_players(state)
      assert state === up_state
    end

    test "active and stopped players should receive message with changes",
       %{state: state, maggots10: maggots, asserter: asserter} do

      stopped = for _ <- 1..10 do
        spawn(asserter)
      end
      active = Map.new(for i <- 1..10 do
        {spawn(asserter), Enum.at(maggots, i)}
      end)

      State.notify_players(%{state | stopped_players: stopped,
                                     players: active})
    end

  end



  defp gen_random_changes(w, h, whats \\  [:bug, :pid]) do
    count_add = :rand.uniform(w * h)
    count_sub = :rand.uniform(w * h)

    adds = for _ <- 1..count_add do
      x = :rand.uniform(w - 1)
      y = :rand.uniform(h - 1)
      what = whats
              |> Enum.take_random(1)
              |> List.first()
      {{x, y}, what}
    end
    subs = for _ <- 1..count_sub do
      x = :rand.uniform(w - 1)
      y = :rand.uniform(h - 1)
      what = [:bug, :pid]
              |> Enum.take_random(1)
              |> List.first()
      {{x, y}, what}
    end

    %Changes{
      +: Map.new(adds),
      -: Map.new(subs)
    }
  end
end
