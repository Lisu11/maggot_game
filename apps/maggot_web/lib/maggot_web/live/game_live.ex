defmodule MaggotWeb.GameLive do
  use MaggotWeb, :live_view
  require Logger
  alias MaggotWeb.{Endpoint, Presence}

  @impl true
  def mount(%{"room_id" => room}, %{"user_token" => token}, socket) do
    Logger.debug(:mount_socket)
    topic = "room:" <> room
    socket = assign_user(socket, token)
    gamers =
        if connected?(socket) do
          Endpoint.subscribe(topic)
          Presence.track(self(), topic, socket.assigns.current_user.username, %{})
          Presence.list(topic) |> Map.keys() |> MapSet.new()
        else
          MapSet.new()
        end
    {:ok, assign(socket,
            topic: topic,
            messages: [],
            gamers: gamers)}
  end

  defp assign_user(socket, token) do
    assign_new(socket, :current_user, fn ->
      Maggot.Accounts.get_user_by_session_token(token)
    end)
  end


  def render_message(%{type: {:private, to}} = msg, current_user, assigns \\ %{}) do
    Logger.debug(maybe_rendering_private_message: msg)
    if current_user.username == to do
      ~L"""
      <li id="<%= msg.id %>" class="list-group-item">
        <strong class="username">
            <%= msg.user %>
        </strong> whispers:
        <div class="message-content text-danger">
          <%= msg.txt %>
        </div>
      </li>
      """
    end
  end
  def render_message(%{type: :system} = msg, _current_user, assigns) do
    Logger.debug(rendering_system_message: msg)
    ~L"""
    <li id="<%= msg.id %>" class="list-group-item text-info">
        <em class="message-content system-message">
            @<strong class="username"><%= msg.user %></strong>
            <%= msg.txt %>
        </em>
    </li>
    """
  end
  def render_message(msg, _current_user, assigns) do
    Logger.debug(rendering_regular_message: msg)
    ~L"""
    <li id="<%= msg.id %>" class="list-group-item">
      <strong class="username"><%= msg.user %></strong> said:
      <div class="message-content">
        <%= msg.txt %>
      </div>
    </li>
    """
  end

  @impl true
  def handle_event("send-message", %{"input" => %{"message" => message, "send_to" => to}}, socket) do
    Logger.info(send_message: message)
    message =
      %{id: UUID.uuid4(),
        txt: message,
        type: regular_or_private(to),
        user: socket.assigns.current_user.username}
    Endpoint.broadcast(socket.assigns.topic, "new-message", message)

    {:noreply, socket}
  end

  defp regular_or_private(to_who) do
    if to_who == "" do
      :regular
    else
      {:private, to_who}
    end
  end

  @impl true
  def handle_info(%{event: "new-message", payload: message}, socket) do
    Logger.info(handle_info: message)

    { :noreply, assign_message(socket, message)}
  end
  @impl true
  def handle_info(%{event: "presence_diff", payload: payload}, socket) do
    {:noreply,
      socket
       |> update_presence(payload)
       |> update_gamers(payload)}
  end

  defp assign_message(socket, %{type: {:private, to}} = msg) do
    messages = if socket.assigns.current_user.username == to, do: [msg], else: []
    assign(socket, messages: messages)
  end
  defp assign_message(socket, msg), do: assign(socket, messages: [msg])


  def gamers_select_options(gamers) do
    for gamer <- gamers do
      gamer
    end
  end

  defp update_gamers(socket, %{joins: j, leaves: l}) do
    assign(socket,
      gamers:
        Map.keys(j)
          # |> IO.inspect()
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
      # |> IO.inspect()
      |> Enum.map(fn u ->
           %{id: UUID.uuid4(),
             txt: status_on_message(status),
             type: :system,
             user: u}
        end)
  end
  defp status_on_message(:joins) do
    "has joined the chat"
  end
  defp status_on_message(:leaves) do
    "has left the chat"
  end
end
