defmodule MaggotWeb.Lobby do

  def get_random_room_id do
    "a"
  end

  def list_public_rooms do
    ["a"]
  end

  def create_new_room(room_id) when is_atom(room_id) do
    MaggotEngine.open_new_room(room_id)
  end

  def join_room(room_id) when is_atom(room_id) do
    MaggotEngine.Game.subscribe(room_id)
  end
end
