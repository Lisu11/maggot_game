defmodule MaggotWeb.GameLive do
  use MaggotWeb, :live_component
  require Logger
  alias MaggotWeb.Endpoint

  @impl true
  def mount(socket) do
    {:ok, assign(socket,
            board: %{},
            width: 300,
            height: 300,
            window_w: 200,
            window_h: 200)}
  end

  @impl true
  def update(assigns, socket) do
   {:ok,
    socket
      |> assign(assigns)
      |> update_board()}
  end



  @impl true
  def handle_event("change-direction",
                   %{"key" => arrow},
                   %{assigns: %{room: room, game_state: :playing}} = socket)
        when arrow in ["ArrowRight", "ArrowLeft", "ArrowUp", "ArrowDown"] do
    Logger.debug(change_direction: arrow)

    MaggotEngine.Game.change_direction(room, arrow_to_direction(arrow))
    {:noreply, socket}
  end
  @impl true
  def handle_event("change-direction", _p, socket), do: {:noreply, socket}

  defp arrow_to_direction("ArrowUp"),    do: :n
  defp arrow_to_direction("ArrowLeft"),  do: :w
  defp arrow_to_direction("ArrowDown"),  do: :s
  defp arrow_to_direction("ArrowRight"), do: :e

  # trzeba zrobic inaczej generowac ID i robic update a nie rysowac wszyystko na nowo
  defp update_board(%{assigns: %{movement: nil}} = socket), do: socket
  defp update_board(%{assigns: %{movement: changes, board: board}} = socket) do
    {_, board} =  changes.+
                    |> Map.merge(board)
                    |> Map.split(Map.keys(changes.-))
    assign(socket, board: board)
  end
end
