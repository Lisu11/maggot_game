defmodule Maggot.Repo do
  use Ecto.Repo,
    otp_app: :maggot,
    adapter: Ecto.Adapters.Postgres
end
