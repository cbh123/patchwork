defmodule Patchwork.Repo do
  use Ecto.Repo,
    otp_app: :patchwork,
    adapter: Ecto.Adapters.Postgres
end
