defmodule NotesAppGcloud.Repo.Migrations.CreateNoteLinks do
  use Ecto.Migration

  def change do
    create table(:note_links, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :from_note_id, references(:notes, type: :binary_id, on_delete: :delete_all), null: false
      add :to_note_id, references(:notes, type: :binary_id, on_delete: :nilify_all)
      add :kind, :string, null: false
      add :label, :string, null: false
      add :url, :text

      timestamps()
    end

    create index(:note_links, [:from_note_id])
    create index(:note_links, [:to_note_id])

    create unique_index(:note_links, [:from_note_id, :kind, :to_note_id, :label],
             name: :note_links_unique
           )
  end
end
