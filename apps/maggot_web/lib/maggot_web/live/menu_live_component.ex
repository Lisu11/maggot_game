defmodule MaggotWeb.MenuLiveComponent do
  use MaggotWeb, :live_component
  require Logger
  alias MaggotWeb.Endpoint

  @impl true
  def mount(socket) do
    socket
      |> assign_nav()
      |> then(&{:ok, &1})
  end

  @impl true
  def update(assigns, socket) do
    { :ok,
      assign(socket, assigns)}
  end

  defp assign_nav(socket) do
    assign(socket, tab: active_nav(:chat))
  end

  @impl true
  def handle_event("change-nav", %{"tab" => tab}, socket) do
    { :noreply,
      assign(socket, tab: active_nav(String.to_existing_atom(tab)))}
  end

  defp active_nav(tab) do
    nav = %{chat: deactivated(), users: deactivated()}
    %{nav | tab =>
        %{nav: "active", pane: "show"}}
  end
  defp deactivated do
    %{nav: "", pane: ""}
  end

  def control_class_for_state(:join, :unsubscribed), do: "disabled"
  def control_class_for_state(:join, :playing), do: "disabled"
  def control_class_for_state(:give_up, :subscribed), do: "disabled"
  def control_class_for_state(:give_up, :unsubscribed), do: "disabled"
  def control_class_for_state(:give_up, :stopped), do: "disabled"
  def control_class_for_state(_, _), do: ""
end
