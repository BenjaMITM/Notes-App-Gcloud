defmodule NotesAppGcloud.Notes.NoteLink do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @kinds ~w(wikilink mention tag url)

  schema "note_links" do
    field :kind, :string
    field :label, :string
    field :url, :string

    belongs_to :from_note, NotesAppGcloud.Notes.Note, foreign_key: :from_note_id
    belongs_to :to_note, NotesAppGcloud.Notes.Note, foreign_key: :to_note_id

    timestamps()
  end

  def changeset(link, attrs) do
    link
    |> cast(attrs, [:kind, :label, :url, :from_note_id, :to_note_id])
    |> validate_required([:kind, :label, :from_note_id])
    |> validate_inclusion(:kind, @kinds)
    |> validate_length(:label, min: 1, max: 500)
    |> validate_length(:url, max: 2000)
  end
end
