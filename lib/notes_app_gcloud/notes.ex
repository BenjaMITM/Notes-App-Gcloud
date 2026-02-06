defmodule NotesAppGcloud.Notes do
  import Ecto.Query, warn: false
  alias NotesAppGcloud.Repo
  alias NotesAppGcloud.Notes.{Note, NoteLink, Parser}

  @link_kinds ["wikilink", "mention"]

  def list_notes(opts \\ %{}) do
    limit = Map.get(opts, :limit, 50)
    search = Map.get(opts, :search)

    Note
    |> maybe_search(search)
    |> order_by([n], desc: n.updated_at)
    |> limit(^limit)
    |> Repo.all()
  end

  def get_note(id) when is_binary(id), do: Repo.get(Note, id)
  def get_note(_), do: nil

  def get_note_by_slug(slug) when is_binary(slug) do
    Repo.get_by(Note, slug: slug)
  end

  def create_note(attrs) do
    Repo.transaction(fn ->
      with {:ok, note} <- %Note{} |> Note.changeset(attrs) |> Repo.insert() do
        rebuild_links(note)
        note
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
    |> normalize_transaction_result()
  end

  def update_note(%Note{} = note, attrs) do
    Repo.transaction(fn ->
      with {:ok, note} <- note |> Note.changeset(attrs) |> Repo.update() do
        rebuild_links(note)
        note
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
    |> normalize_transaction_result()
  end

  def delete_note(%Note{} = note) do
    Repo.delete(note)
  end

  def list_outgoing_links(note_id) do
    from(l in NoteLink,
      where: l.from_note_id == ^note_id,
      order_by: [asc: l.kind, asc: l.label]
    )
    |> Repo.all()
  end

  def list_incoming_links(note_id) do
    from(l in NoteLink,
      where: l.to_note_id == ^note_id,
      order_by: [asc: l.kind, asc: l.label]
    )
    |> Repo.all()
  end

  def list_link_labels(note_id, kind) do
    from(l in NoteLink,
      where: l.from_note_id == ^note_id and l.kind == ^kind,
      distinct: true,
      select: l.label,
      order_by: [asc: l.label]
    )
    |> Repo.all()
  end

  def brain_view(note_id, related_limit \\ 12) do
    parents =
      from(l in NoteLink,
        join: n in Note,
        on: n.id == l.from_note_id,
        where: l.to_note_id == ^note_id and l.kind in ^@link_kinds,
        select: n,
        distinct: true
      )
      |> Repo.all()

    children =
      from(l in NoteLink,
        join: n in Note,
        on: n.id == l.to_note_id,
        where: l.from_note_id == ^note_id and l.kind in ^@link_kinds and not is_nil(l.to_note_id),
        select: n,
        distinct: true
      )
      |> Repo.all()

    tags = list_link_labels(note_id, "tag")

    siblings =
      if tags == [] do
        []
      else
        from(l in NoteLink,
          join: n in Note,
          on: n.id == l.from_note_id,
          where:
            l.kind == "tag" and l.label in ^tags and n.id != ^note_id,
          group_by: n.id,
          order_by: [desc: count(n.id)],
          select: n,
          limit: ^related_limit
        )
        |> Repo.all()
      end

    %{
      parents: parents,
      children: children,
      siblings: siblings
    }
  end

  def graph(note_id, depth \\ 1) do
    depth = max(depth, 1)
    {nodes, edges, depth_map} = build_graph(note_id, depth)

    %{
      nodes:
        Enum.map(nodes, fn note ->
          %{note: note, depth: Map.get(depth_map, note.id, 0)}
        end),
      edges: edges
    }
  end

  defp build_graph(note_id, depth) do
    visited = MapSet.new([note_id])
    depth_map = %{note_id => 0}
    frontier = MapSet.new([note_id])
    edges = MapSet.new()

    {visited, edges, depth_map, _frontier} =
      Enum.reduce(1..depth, {visited, edges, depth_map, frontier}, fn level,
                                                                       {visited_acc, edges_acc, depth_acc, frontier_acc} ->
        frontier_ids = MapSet.to_list(frontier_acc)

        step_edges =
          from(l in NoteLink,
            where:
              (l.from_note_id in ^frontier_ids or l.to_note_id in ^frontier_ids) and
                l.kind in ^@link_kinds and not is_nil(l.to_note_id),
            select: %{from_id: l.from_note_id, to_id: l.to_note_id, kind: l.kind, label: l.label}
          )
          |> Repo.all()

        edges_acc =
          Enum.reduce(step_edges, edges_acc, fn edge, acc ->
            MapSet.put(acc, edge)
          end)

        new_node_ids =
          step_edges
          |> Enum.flat_map(fn edge -> [edge.from_id, edge.to_id] end)
          |> Enum.reject(&is_nil/1)
          |> Enum.reject(&MapSet.member?(visited_acc, &1))

        visited_acc = Enum.reduce(new_node_ids, visited_acc, &MapSet.put(&2, &1))
        depth_acc = Enum.reduce(new_node_ids, depth_acc, &Map.put(&2, &1, level))
        frontier_acc = MapSet.new(new_node_ids)
        {visited_acc, edges_acc, depth_acc, frontier_acc}
      end)

    notes =
      from(n in Note, where: n.id in ^MapSet.to_list(visited))
      |> Repo.all()

    {notes, MapSet.to_list(edges), depth_map}
  end

  defp rebuild_links(%Note{} = note) do
    parsed = Parser.extract_links(note.body)

    Repo.delete_all(from(l in NoteLink, where: l.from_note_id == ^note.id))

    slug_targets =
      parsed
      |> Enum.map(& &1.target_slug)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    slug_map =
      if slug_targets == [] do
        %{}
      else
        from(n in Note, where: n.slug in ^slug_targets, select: {n.slug, n.id})
        |> Repo.all()
        |> Map.new()
      end

    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    rows =
      Enum.map(parsed, fn link ->
        %{
          id: Ecto.UUID.generate(),
          from_note_id: note.id,
          to_note_id: Map.get(slug_map, link.target_slug),
          kind: link.kind,
          label: link.label,
          url: link.url,
          inserted_at: now,
          updated_at: now
        }
      end)

    if rows != [] do
      Repo.insert_all(NoteLink, rows,
        on_conflict: :nothing,
        conflict_target: [:from_note_id, :kind, :to_note_id, :label]
      )
    end

    :ok
  end

  defp maybe_search(query, nil), do: query
  defp maybe_search(query, ""), do: query

  defp maybe_search(query, search) do
    like = "%#{search}%"

    from(n in query,
      where: ilike(n.title, ^like) or ilike(n.body, ^like)
    )
  end

  defp normalize_transaction_result({:ok, note}), do: {:ok, note}
  defp normalize_transaction_result({:error, %Ecto.Changeset{} = changeset}), do: {:error, changeset}
end
