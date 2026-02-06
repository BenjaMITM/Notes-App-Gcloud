defmodule NotesAppGcloudWeb.Schema.Types do
  use Absinthe.Schema.Notation

  alias NotesAppGcloudWeb.Resolvers

  object :note do
    field :id, non_null(:id)
    field :title, non_null(:string)
    field :slug, non_null(:string)
    field :body, non_null(:string)
    field :inserted_at, non_null(:naive_datetime)
    field :updated_at, non_null(:naive_datetime)

    field :outgoing_links, non_null(list_of(non_null(:note_link))),
      resolve: &Resolvers.Notes.outgoing_links/3

    field :incoming_links, non_null(list_of(non_null(:note_link))),
      resolve: &Resolvers.Notes.incoming_links/3

    field :tags, non_null(list_of(non_null(:string))),
      resolve: &Resolvers.Notes.tags/3

    field :mentions, non_null(list_of(non_null(:string))),
      resolve: &Resolvers.Notes.mentions/3
  end

  object :note_link do
    field :id, non_null(:id)
    field :kind, non_null(:string)
    field :label, non_null(:string)
    field :url, :string
    field :from_id, non_null(:id), resolve: fn link, _, _ -> {:ok, link.from_note_id} end
    field :to_id, :id, resolve: fn link, _, _ -> {:ok, link.to_note_id} end

    field :to_note, :note do
      resolve &Resolvers.Notes.link_to_note/3
    end

    field :from_note, :note do
      resolve &Resolvers.Notes.link_from_note/3
    end
  end

  input_object :note_input do
    field :title, non_null(:string)
    field :body, non_null(:string)
  end

  object :brain_view do
    field :focus, non_null(:note)
    field :parents, non_null(list_of(non_null(:note)))
    field :children, non_null(list_of(non_null(:note)))
    field :siblings, non_null(list_of(non_null(:note)))
  end

  object :graph_node do
    field :note, non_null(:note)
    field :depth, non_null(:integer)
  end

  object :graph_edge do
    field :from_id, non_null(:id)
    field :to_id, non_null(:id)
    field :kind, non_null(:string)
    field :label, non_null(:string)
  end

  object :graph do
    field :nodes, non_null(list_of(non_null(:graph_node)))
    field :edges, non_null(list_of(non_null(:graph_edge)))
  end
end
