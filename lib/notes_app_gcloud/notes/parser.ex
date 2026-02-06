defmodule NotesAppGcloud.Notes.Parser do
  alias NotesAppGcloud.Notes.Note

  @wikilink ~r/\[\[([^\]]+)\]\]/
  @tag ~r/(?<![\p{L}\p{N}_])#([\p{L}\p{N}_-]{1,50})/u
  @mention ~r/(?<![\p{L}\p{N}_])@([\p{L}\p{N}_-]{1,50})/u
  @url ~r/\bhttps?:\/\/[^\s\)]+/i

  def extract_links(body) when is_binary(body) do
    links =
      []
      |> add_wikilinks(body)
      |> add_tags(body)
      |> add_mentions(body)
      |> add_urls(body)

    links
    |> Enum.uniq_by(fn link -> {link.kind, link.label, link.url} end)
  end

  def extract_links(_), do: []

  defp add_wikilinks(links, body) do
    wikilinks =
      @wikilink
      |> Regex.scan(body)
      |> Enum.map(fn [_, raw_target] ->
        target =
          raw_target
          |> String.split("|")
          |> List.first()
          |> String.trim()

        %{
          kind: "wikilink",
          label: target,
          url: nil,
          target_slug: Note.slugify(target)
        }
      end)

    links ++ wikilinks
  end

  defp add_tags(links, body) do
    tags =
      @tag
      |> Regex.scan(body)
      |> Enum.map(fn [_, raw_tag] ->
        tag = String.downcase(raw_tag)

        %{
          kind: "tag",
          label: tag,
          url: nil,
          target_slug: nil
        }
      end)

    links ++ tags
  end

  defp add_mentions(links, body) do
    mentions =
      @mention
      |> Regex.scan(body)
      |> Enum.map(fn [_, raw_mention] ->
        mention = String.downcase(raw_mention)

        %{
          kind: "mention",
          label: mention,
          url: nil,
          target_slug: Note.slugify(mention)
        }
      end)

    links ++ mentions
  end

  defp add_urls(links, body) do
    urls =
      @url
      |> Regex.scan(body)
      |> Enum.map(fn [url] ->
        %{
          kind: "url",
          label: url,
          url: url,
          target_slug: nil
        }
      end)

    links ++ urls
  end
end
