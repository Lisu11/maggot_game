defmodule MaggotWeb.RoomLive do
  use MaggotWeb, :live_view
  require Logger
  alias MaggotWeb.{Endpoint, Presence}

  @impl true
  def mount(%{"room_id" => room}, %{"user_token" => token}, socket) do
    Logger.debug(:mount_socket)
    topic = "room:" <> room
    room_atom = String.to_atom(room)
    socket = assign_user(socket, token)
    initial_presence =
        if connected?(socket) do
          Endpoint.subscribe(topic)
          Presence.track(self(), topic, socket.assigns.current_user.username, %{})
          MaggotEngine.open_new_room(room_atom)
          MaggotEngine.Game.add_player(room_atom)
          Presence.list(topic) |> Map.keys() |> MapSet.new()
        else
          MapSet.new()
        end
    {:ok, assign(socket,
            topic: topic,
            room: room_atom,
            raw_message: nil,
            movement: nil,
            presence_diff: nil,
            initial_presence: initial_presence)}
  end

  defp assign_user(socket, token) do
    assign_new(socket, :current_user, fn ->
      Maggot.Accounts.get_user_by_session_token(token)
    end)
  end

  @impl true
  def handle_info(%{event: "new-message", payload: message}, socket) do
    Logger.info(handle_info: message)

    { :noreply, assign(socket, :raw_message, message)}
  end
  @impl true
  def handle_info(%{event: "presence_diff", payload: payload}, socket) do
    {:noreply, assign(socket, :presence_diff, payload)}
  end
  @impl true
  def handle_info(:presence_diff_consumed, socket) do
    Logger.debug(:presence_diff_consumed)
    {:noreply, assign(socket, :presence_diff, nil)}
  end
  @impl true
  def handle_info({:change, changes}, socket) do
    # Logger.debug(changes: changes)
    socket = assign(socket, :movement, changes)
    {:noreply, socket}
  end


end
