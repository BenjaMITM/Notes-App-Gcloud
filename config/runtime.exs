import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/notes_app_gcloud start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :notes_app_gcloud, NotesAppGcloudWeb.Endpoint, server: true
end

config :notes_app_gcloud, NotesAppGcloudWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

cors_origins =
  System.get_env("CORS_ORIGINS", "")
  |> String.split(",", trim: true)
  |> Enum.map(&String.trim/1)

if cors_origins != [] do
  config :notes_app_gcloud, :cors, origins: cors_origins
end

if config_env() == :prod do
  build_socket_database_url = fn ->
    user = System.get_env("DB_USER")
    password = System.get_env("DB_PASSWORD")
    database = System.get_env("DB_NAME")
    socket = System.get_env("DB_SOCKET")
    instance = System.get_env("INSTANCE_CONNECTION_NAME")

    host =
      cond do
        is_binary(socket) and socket != "" -> socket
        is_binary(instance) and instance != "" -> "/cloudsql/#{instance}"
        true -> nil
      end

    if is_binary(user) and user != "" and is_binary(database) and database != "" and is_binary(host) and host != "" do
      encoded_password =
        if is_binary(password) and password != "" do
          ":" <> URI.encode_www_form(password)
        else
          ""
        end

      encoded_host = URI.encode_www_form(host)

      "ecto://#{user}#{encoded_password}@/#{database}?host=#{encoded_host}"
    else
      nil
    end
  end

  database_url =
    System.get_env("DATABASE_URL") ||
      build_socket_database_url.() ||
      raise """
      DATABASE_URL is missing and DB_USER/DB_PASSWORD/DB_NAME/DB_SOCKET (or INSTANCE_CONNECTION_NAME) are not set.
      Example (socket): ecto://USER:PASS@/DATABASE?host=/cloudsql/PROJECT:REGION:INSTANCE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :notes_app_gcloud, NotesAppGcloud.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    # For machines with several cores, consider starting multiple pools of `pool_size`
    # pool_count: 4,
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "localhost"

  config :notes_app_gcloud, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :notes_app_gcloud, NotesAppGcloudWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :notes_app_gcloud, NotesAppGcloudWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :notes_app_gcloud, NotesAppGcloudWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Here is an example configuration for Mailgun:
  #
  #     config :notes_app_gcloud, NotesAppGcloud.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # Most non-SMTP adapters require an API client. Swoosh supports Req, Hackney,
  # and Finch out-of-the-box. This configuration is typically done at
  # compile-time in your config/prod.exs:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Req
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
