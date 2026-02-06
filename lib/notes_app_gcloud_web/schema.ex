defmodule NotesAppGcloudWeb.Schema do
  use Absinthe.Schema

  import_types Absinthe.Type.Custom
  import_types NotesAppGcloudWeb.Schema.Types

  alias NotesAppGcloudWeb.Resolvers

  query do
    field :note, :note do
      arg :id, non_null(:id)
      resolve &Resolvers.Notes.get_note/3
    end

    field :note_by_slug, :note do
      arg :slug, non_null(:string)
      resolve &Resolvers.Notes.get_note_by_slug/3
    end

    field :notes, non_null(list_of(non_null(:note))) do
      arg :limit, :integer
      arg :search, :string
      resolve &Resolvers.Notes.list_notes/3
    end

    field :brain_view, :brain_view do
      arg :id, non_null(:id)
      arg :related_limit, :integer, default_value: 12
      resolve &Resolvers.Notes.brain_view/3
    end

    field :graph, :graph do
      arg :id, non_null(:id)
      arg :depth, :integer, default_value: 1
      resolve &Resolvers.Notes.graph/3
    end
  end

  mutation do
    field :create_note, :note do
      arg :input, non_null(:note_input)
      resolve &Resolvers.Notes.create_note/3
    end

    field :update_note, :note do
      arg :id, non_null(:id)
      arg :input, non_null(:note_input)
      resolve &Resolvers.Notes.update_note/3
    end

    field :delete_note, non_null(:boolean) do
      arg :id, non_null(:id)
      resolve &Resolvers.Notes.delete_note/3
    end
  end
end
