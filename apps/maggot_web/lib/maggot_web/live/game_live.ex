defmodule MaggotWeb.GameLive do
  use MaggotWeb, :live_component
  require Logger
  alias MaggotWeb.Endpoint

  def mount(socket) do
    {:ok, assign(socket, board: %{})}
  end

  def update(assigns, socket) do
   {:ok,
    socket
      |> assign(assigns)
      |> update_board()}
  end
# trzeba zrobic inaczej generowac ID i robic update a nie rysowac wszyystko na nowo
  defp update_board(%{assigns: %{movement: nil, board: board}} = socket), do: socket
  defp update_board(%{assigns: %{movement: changes, board: board}} = socket) do
    {_, board} =  changes.+
                    |> Map.merge(board)
                    |> Map.split(Map.keys(changes.-))
    assign(socket, board: board)
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
