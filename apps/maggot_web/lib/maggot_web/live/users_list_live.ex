defmodule MaggotWeb.UsersListLive do
  use MaggotWeb, :live_component
  require Logger
  alias MaggotWeb.Endpoint

  def mount(socket) do
    {:ok,
      socket
        |> assign(users: nil)}
  end

  def update(assigns, socket) do
    {:ok,
      socket
        |> assign(assigns)
        |> assign_users()}
  end

  def assign_users(socket) do
    socket
  end
end
