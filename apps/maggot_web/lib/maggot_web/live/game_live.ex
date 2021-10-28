defmodule MaggotWeb.GameLive do
  use MaggotWeb, :live_component
  require Logger
  alias MaggotWeb.Endpoint


  def render_mesh(assigns) do

  end

  def handle_event("change-direction", %{"key" => "ArrowRight"}, %{assigns: %{room: room}} = socket) do
    Logger.debug(change_direction: :right)
    MaggotEngine.Game.change_direction(room, :e)
    {:noreply, socket}
  end
  def handle_event("change-direction", %{"key" => "ArrowLeft"},  %{assigns: %{room: room}} = socket) do
    Logger.debug(change_direction: :right)
    MaggotEngine.Game.change_direction(room, :w)
    {:noreply, socket}
  end
  def handle_event("change-direction", %{"key" => "ArrowUp"},  %{assigns: %{room: room}} = socket) do
    Logger.debug(change_direction: :up)
    MaggotEngine.Game.change_direction(room, :n)
    {:noreply, socket}
  end
  def handle_event("change-direction", %{"key" => "ArrowDown"},  %{assigns: %{room: room}} = socket) do
    Logger.debug(change_direction: :down)
    MaggotEngine.Game.change_direction(room, :s)
    {:noreply, socket}
  end
  def handle_event("change-direction", _p, socket), do: {:noreply, socket}


end
