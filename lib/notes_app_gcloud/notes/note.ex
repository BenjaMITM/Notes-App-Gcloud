defmodule NotesAppGcloud.Notes.Note do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "notes" do
    field :title, :string
    field :slug, :string
    field :body, :string

    has_many :outgoing_links, NotesAppGcloud.Notes.NoteLink, foreign_key: :from_note_id
    has_many :incoming_links, NotesAppGcloud.Notes.NoteLink, foreign_key: :to_note_id

    timestamps()
  end

  def changeset(note, attrs) do
    note
    |> cast(attrs, [:title, :body, :slug])
    |> update_change(:title, &String.trim/1)
    |> update_change(:body, &String.trim/1)
    |> validate_required([:title, :body])
    |> validate_length(:title, min: 1, max: 200)
    |> validate_length(:body, min: 1)
    |> maybe_put_slug()
    |> unique_constraint(:slug)
  end

  def slugify(title) when is_binary(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
    |> case do
      "" -> "note"
      slug -> slug
    end
  end

  def slugify(_), do: "note"

  defp maybe_put_slug(changeset) do
    slug = get_field(changeset, :slug)
    title = get_field(changeset, :title)

    cond do
      is_binary(slug) and slug != "" ->
        changeset

      is_binary(title) ->
        put_change(changeset, :slug, slugify(title))

      true ->
        changeset
    end
  end
end
