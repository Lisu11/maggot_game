defmodule MaggotWeb.ChatLive do
  use MaggotWeb, :live_component
  require Logger
  alias MaggotWeb.Endpoint

  def mount(socket) do
    IO.inspect("------------------------")
    IO.inspect(socket)
    {:ok, socket}
  end

  @impl true
  def handle_event("send-message", %{"input" => %{"message" => message}}, socket) do
    Logger.info(socket)
    Endpoint.broadcast(socket.assigns.topic, "new-message", message)
    {:noreply, socket}
  end


end
