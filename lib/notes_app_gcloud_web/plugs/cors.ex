defmodule NotesAppGcloudWeb.Plugs.Cors do
  @behaviour Plug
  import Plug.Conn

  @allowed_methods "GET,POST,PUT,PATCH,DELETE,OPTIONS"
  @allowed_headers "authorization,content-type"

  def init(opts), do: opts

  def call(conn, _opts) do
    origins =
      Application.get_env(:notes_app_gcloud, :cors, [])
      |> Keyword.get(:origins, [])

    origin =
      case get_req_header(conn, "origin") do
        [value | _] -> value
        _ -> nil
      end

    conn =
      cond do
        origins == ["*"] ->
          put_resp_header(conn, "access-control-allow-origin", "*")

        is_binary(origin) and Enum.member?(origins, origin) ->
          conn
          |> put_resp_header("access-control-allow-origin", origin)
          |> put_resp_header("vary", "origin")

        true ->
          conn
      end

    conn =
      conn
      |> put_resp_header("access-control-allow-methods", @allowed_methods)
      |> put_resp_header("access-control-allow-headers", @allowed_headers)
      |> put_resp_header("access-control-allow-credentials", "true")

    if conn.method == "OPTIONS" do
      conn
      |> send_resp(204, "")
      |> halt()
    else
      conn
    end
  end
end
