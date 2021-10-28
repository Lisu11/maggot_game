defmodule MaggotWeb.UserSessionController do
  use MaggotWeb, :controller

  alias Maggot.Accounts
  alias MaggotWeb.UserAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"email_or_username" => eou, "password" => password} = user_params
    getter =
      if eou =~ ~r/@/ do
        &Accounts.get_user_by_email_and_password(&1, &2)
      else
        &Accounts.get_user_by_username_and_password(&1, &2)
      end
    if user = getter.(eou, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      render(conn, "new.html", error_message: "Invalid username, email or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
