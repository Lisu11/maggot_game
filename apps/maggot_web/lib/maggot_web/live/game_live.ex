defmodule MaggotWeb.GameLive do
  use MaggotWeb, :live_view
  require Logger
  alias MaggotWeb.{Endpoint, Presence}

  @impl true
  def mount(%{"room_id" => room}, _session, socket) do
    Logger.debug(:mount_socket)
    topic = "room:" <> room
    username =  UUID.uuid1() # replace it and get user from session
    gamers =
        if connected?(socket) do
          Endpoint.subscribe(topic)
          Presence.track(self(), topic, username, %{})
          Presence.list(topic) |> Map.keys() |> MapSet.new()
        else
          MapSet.new()
        end
    {:ok, assign(socket,
            topic: topic,
            messages: [],
            username: username,
            gamers: gamers)}
  end

  @impl true
  def handle_event("send-message", %{"input" => %{"message" => message}}, socket) do
    Logger.info(send_message: message)
    message = %{id: UUID.uuid4(), txt: message, type: :regular, user: socket.assigns.username}
    Endpoint.broadcast(socket.assigns.topic, "new-message", message)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "new-message", payload: message}, socket) do
    Logger.info(handle_info: message)
    { :noreply,
      socket
       |> assign(messages: [message])}
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: payload}, socket) do
    {:noreply,
      socket
       |> update_presence(payload)
       |> update_gamers(payload)}
  end

  defp update_gamers(socket, %{joins: j, leaves: l}) do
    assign(socket,
      gamers:
        Map.keys(j)
          |> MapSet.new()
          |> MapSet.union(socket.assigns.gamers)
          |> MapSet.difference(MapSet.new(Map.keys(l))))
  end

  defp update_presence(socket, payload) do
    [j_msgs, l_msgs] =
      for {status, diffs} <- payload do
         diffs_to_messages(diffs, status)
      end
    assign(socket, messages: j_msgs ++ l_msgs)
  end

  defp diffs_to_messages(diff, status) do
    diff
      |> Map.keys()
      |> Enum.map(fn u ->
           %{id: UUID.uuid4(),
             txt: status_on_message(u, status),
             type: :system,
             user: u}
        end)
  end
  defp status_on_message(username, :joins) do
    "#{username} has joined the chat"
  end
  defp status_on_message(username, :leaves) do
    "#{username} has left the chat"
  end
end
