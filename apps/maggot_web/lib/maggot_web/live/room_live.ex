defmodule MaggotWeb.RoomLive do
  use MaggotWeb, :live_view
  require Logger
  alias MaggotWeb.{Endpoint, Presence}

  @impl true
  def mount(%{"room_id" => room}, %{"user_token" => token}, socket) do
    Logger.debug(mount: __MODULE__)
    topic = "room:" <> room
    room_atom = String.to_atom(room)
    socket =  socket
      |> assign_user(token)
      |> subscribe_if_connected(topic, room_atom)
      |> init_presence(topic)

    {:ok, assign(socket,
            topic: topic,
            room: room_atom,
            room_id: room,
            raw_message: nil,
            movement: nil,
            presence_diff: nil)}
  end


  @impl true
  def handle_info(%{event: "new-message", payload: message}, socket) do
    Logger.info(handle_info: message)

    { :noreply, assign(socket, :raw_message, message)}
  end
  @impl true
  def handle_info(%{event: "presence_diff", payload: payload}, socket) do
    { :noreply,
      socket
        |> assign(:presence_diff, payload)
        |> update_presence(payload)
    }
  end
  @impl true
  def handle_info(:presence_diff_consumed, socket) do
    Logger.debug(presence_diff_consumed: true)
    {:noreply, assign(socket, :presence_diff, nil)}
  end
  @impl true
  def handle_info({:change, changes}, socket) do
    # Logger.debug(changes: changes)
    socket = assign(socket, :movement, changes)
    if changes.stops[self()] do
      {:noreply, socket
        |> put_flash(:info, "You've lost")
        |> assign(game_state: :stopped)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_params(%{"game_action" => "join"}, _uri, socket) do
    { :noreply,
      with :ok <- MaggotEngine.Game.join_game(socket.assigns.room) do
         assign(socket, game_state: :playing)
      else
        error ->
          Logger.error(joining_error: inspect(error))
          socket
      end}
  end
  @impl true
  def handle_params(_params, _uri, socket), do: { :noreply, socket }

  defp init_presence(socket, topic) do
    assign(socket,
           :presence,
            if connected? socket do
              Presence.track(self(), topic, socket.assigns.current_user.username, %{})
              Presence.list(topic) |> Map.keys() |> MapSet.new()
            else
              MapSet.new()
            end)
  end
  defp subscribe_if_connected(socket, topic, room) do
    if connected? socket do
      Endpoint.subscribe(topic)
      MaggotEngine.open_new_room(room)
      MaggotEngine.Game.subscribe(room)
      assign(socket, game_state: :subscribed)
    else
      assign(socket, game_state: :unsubscribed)
    end
  end

  defp assign_user(socket, token) do
    assign_new(socket, :current_user, fn ->
      Maggot.Accounts.get_user_by_session_token(token)
    end)
  end

  defp update_presence(socket, %{joins: j, leaves: l}) do
  assign(socket,
    presence:
      Map.keys(j)
        |> MapSet.new()
        |> MapSet.union(socket.assigns.presence)
        |> MapSet.difference(MapSet.new(Map.keys(l))))
  end

end
