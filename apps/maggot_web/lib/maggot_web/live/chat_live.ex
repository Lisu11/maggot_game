defmodule MaggotWeb.ChatLive do
  use MaggotWeb, :live_component
  require Logger
  alias MaggotWeb.Endpoint


  @impl true
  def mount(socket) do
    # IO.inspect(socket)
    {:ok, assign(socket,
                  gamers: nil,
                  messages: [])}
  end

  @impl true
  def update(%{presence_diff: diff} = assigns, socket) do
    socket
     |> parse_diff(assigns.presence_diff)
     |> Kernel.then(fn s -> {:ok, s} end)
  end
  @impl true
  def update(assigns, socket) do
    socket
     |> assign(assigns)
     |> assign_gamers(assigns.presence)
     |> parse_message(assigns.raw_message, assigns.current_user)
     |> Kernel.then(fn s -> {:ok, s} end)
  end

  @impl true
  def handle_event("send-message", %{"input" => %{"message" => message, "send_to" => to}}, socket) do
    Logger.info(send_message: message)
    message =
      %{id: UUID.uuid4(),
        txt: message,
        type: regular_or_private(to),
        user: socket.assigns.current_user.username,
        time: Time.utc_now()
              |> Time.to_string()
              |> String.split(".")
              |> List.first()}
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


  def gamers_select_options(gamers) do
    for gamer <- gamers do
      gamer
    end
  end

  def render_message(msg, current_user, assigns \\ %{})
  def render_message(%{type: {:private, to}} = msg, current_user, assigns) do
    Logger.debug(maybe_rendering_private_message: msg)
    if current_user.username == to do
      ~L"""
      <li id="<%= msg.id %>" class="list-group-item">
        <div class="list-group-item-heading">
        <strong class="username">
            <%= msg.user %>
        </strong> whispers:
        </div>
        <div class="list-group-item-text message-content text-danger">
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
      <div class="list-group-item-heading d-flex justify-content-between">
        <h5 class="message-heading-user d-flex">
          <div class="username mr-1">@<%= msg.user %></div>
          <span class="user-said">said:</span>
        </h5>
        <small class="message-date"><%= msg.time %></small>
      </div>
      <div class="list-group-item-text message-content">
        <%= msg.txt %>
      </div>
    </li>
    """
  end

  defp assign_gamers(%{assigns: %{gamers: nil}} = socket, init) do
    assign(socket, :gamers, init)
  end
  defp assign_gamers(socket, _), do: socket

  defp parse_diff(socket, nil), do: socket
  defp parse_diff(%{assigns: %{messages: messages}} = socket, payload) do
    messages =
      Enum.reduce(payload, messages, fn {status, diffs}, acc ->
          acc ++ diffs_to_messages(diffs, status)
        end)

    assign(socket, messages: messages)
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
