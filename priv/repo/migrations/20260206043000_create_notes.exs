defmodule NotesAppGcloud.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :slug, :string, null: false
      add :body, :text, null: false

      timestamps()
    end

    create unique_index(:notes, [:slug])
  end
end
