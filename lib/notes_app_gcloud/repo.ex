defmodule NotesAppGcloud.Repo do
  use Ecto.Repo,
    otp_app: :notes_app_gcloud,
    adapter: Ecto.Adapters.Postgres
end
