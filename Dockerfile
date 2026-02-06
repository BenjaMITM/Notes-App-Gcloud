FROM hexpm/elixir:1.16.3-erlang-26.2.5-alpine-3.19 AS build

ENV MIX_ENV=prod
WORKDIR /app

RUN apk add --no-cache build-base git

COPY mix.exs mix.lock ./
COPY config config
RUN mix local.hex --force && mix local.rebar --force
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

COPY lib lib
COPY priv priv

RUN mix compile
RUN mix release

FROM alpine:3.19 AS app

RUN apk add --no-cache libstdc++ openssl ncurses-libs

ENV MIX_ENV=prod
ENV PHX_SERVER=true
ENV PORT=8080

WORKDIR /app
COPY --from=build /app/_build/prod/rel/notes_app_gcloud ./

EXPOSE 8080
CMD ["/app/bin/notes_app_gcloud", "start"]
