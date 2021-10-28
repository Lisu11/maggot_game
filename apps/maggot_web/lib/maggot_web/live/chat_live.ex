defmodule MaggotWeb.ChatLive do
  use MaggotWeb, :live_component
  require Logger
  alias MaggotWeb.Endpoint


  @impl true
  def mount(socket) do
    # IO.inspect(socket)
    {:ok, assign(socket, :gamers, nil)}
  end

  @impl true
  def update(assigns, socket) do
    socket
    #  |> IO.inspect()
     |> assign(assigns)
     |> assign_gamers(assigns.initial_presence)
    #  |> IO.inspect()
     |> parse_message(assigns.raw_message, assigns.current_user)
    #  |> IO.inspect()
     |> parse_diff(assigns.presence_diff)
    #  |> IO.inspect()
     |> Kernel.then(fn s -> {:ok, s} end)
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

  defp parse_message(socket, %{type: {:private, to}} = msg, user) do
    messages = if user.username == to, do: [msg], else: []
    assign(socket, messages: messages)
  end
  defp parse_message(socket, msg, _user) do
    if msg, do: assign(socket, messages: [msg]), else: socket
  end

  defp parse_diff(socket, nil), do: socket
  defp parse_diff(socket, diff) do
    socket
      |> update_presence(diff)
      |> update_gamers(diff)
  end

  def gamers_select_options(gamers) do
    for gamer <- gamers do
      gamer
    end
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

  defp assign_gamers(%{assigns: %{gamers: nil}} = socket, init) do
    assign(socket, :gamers, init)
  end
  defp assign_gamers(socket, _), do: socket

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
    messages = socket.assigns.messages
    [j_msgs, l_msgs] =
      for {status, diffs} <- payload do
         diffs_to_messages(diffs, status)
      end
    send(self(), :presence_diff_consumed)
    assign(socket,
      messages: messages ++ j_msgs ++ l_msgs,
      presence_diff: nil)
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
