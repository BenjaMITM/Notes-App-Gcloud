defmodule NotesAppGcloudWeb.Resolvers.Notes do
  alias NotesAppGcloud.Notes
  alias NotesAppGcloud.Notes.Note

  def list_notes(_parent, args, _resolution) do
    {:ok, Notes.list_notes(args)}
  end

  def get_note(_parent, %{id: id}, _resolution) do
    {:ok, Notes.get_note(id)}
  end

  def get_note_by_slug(_parent, %{slug: slug}, _resolution) do
    {:ok, Notes.get_note_by_slug(slug)}
  end

  def create_note(_parent, %{input: input}, _resolution) do
    with {:ok, note} <- Notes.create_note(input) do
      {:ok, note}
    else
      {:error, changeset} -> {:error, message_from_changeset(changeset)}
    end
  end

  def update_note(_parent, %{id: id, input: input}, _resolution) do
    with %Note{} = note <- Notes.get_note(id),
         {:ok, note} <- Notes.update_note(note, input) do
      {:ok, note}
    else
      nil -> {:error, "note_not_found"}
      {:error, changeset} -> {:error, message_from_changeset(changeset)}
    end
  end

  def delete_note(_parent, %{id: id}, _resolution) do
    with %Note{} = note <- Notes.get_note(id),
         {:ok, _} <- Notes.delete_note(note) do
      {:ok, true}
    else
      nil -> {:ok, false}
      {:error, _} -> {:ok, false}
    end
  end

  def outgoing_links(%Note{id: id}, _args, _resolution) do
    {:ok, Notes.list_outgoing_links(id)}
  end

  def incoming_links(%Note{id: id}, _args, _resolution) do
    {:ok, Notes.list_incoming_links(id)}
  end

  def tags(%Note{id: id}, _args, _resolution) do
    {:ok, Notes.list_link_labels(id, "tag")}
  end

  def mentions(%Note{id: id}, _args, _resolution) do
    {:ok, Notes.list_link_labels(id, "mention")}
  end

  def link_to_note(link, _args, _resolution) do
    {:ok, Notes.get_note(link.to_note_id)}
  end

  def link_from_note(link, _args, _resolution) do
    {:ok, Notes.get_note(link.from_note_id)}
  end

  def brain_view(_parent, %{id: id} = args, _resolution) do
    with %Note{} = note <- Notes.get_note(id) do
      related_limit = Map.get(args, :related_limit, 12)
      view = Notes.brain_view(id, related_limit)
      {:ok, Map.put(view, :focus, note)}
    else
      nil -> {:error, "note_not_found"}
    end
  end

  def graph(_parent, %{id: id} = args, _resolution) do
    with %Note{} <- Notes.get_note(id) do
      depth = Map.get(args, :depth, 1)
      {:ok, Notes.graph(id, depth)}
    else
      nil -> {:error, "note_not_found"}
    end
  end

  defp message_from_changeset(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map_join(", ", fn {field, errors} ->
      "#{field} #{Enum.join(errors, ", ")}"
    end)
  end
end
