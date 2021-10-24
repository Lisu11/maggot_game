defmodule MaggotWeb.GameLive do
  use MaggotWeb, :live_view
  require Logger
  alias MaggotWeb.{Endpoint, Presence}

  @impl true
  def mount(%{"room_id" => room}, _session, socket) do
    Logger.debug(:mount_socket)
    topic = "room:" <> room
    username =  UUID.uuid1() # replace it and get user from session
    if connected?(socket) do
      Endpoint.subscribe(topic)
      Presence.track(self(), topic, username, %{})
    end
    {:ok, assign(socket,
            topic: topic,
            messages: [],
            username: username)}
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
    broadcast_presence(payload, socket.assigns.topic)
    {:noreply, socket}
  end

  defp broadcast_presence(payload, topic) do
    Enum.each(payload, fn {status, diffs} ->
      for msg <- diffs_to_messages(diffs, status) do
        Endpoint.broadcast(topic, "new-message", msg)
      end
    end)
  end
  defp diffs_to_messages(diff, status) do
    diff
      |> Map.keys()
      |> Enum.map(fn u ->
          %{id: UUID.uuid4(),
            txt: status_on_message(u, status),
            type: :system}
        end)
  end
  defp status_on_message(username, :joins) do
    "#{username} has joined the chat"
  end
  defp status_on_message(username, :leaves) do
    "#{username} has left the chat"
  end
end
