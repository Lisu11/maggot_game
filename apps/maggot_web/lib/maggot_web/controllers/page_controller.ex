defmodule MaggotWeb.PageController do
  use MaggotWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
