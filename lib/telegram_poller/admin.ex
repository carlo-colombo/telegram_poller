defmodule TelegramPoller.Admin do
  @moduledoc false

  use Plug.Router
  alias TelegramPoller.Hook

  plug(Plug.Logger)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:match)
  plug(:dispatch)

  get "/api/hooks" do
    conn
    |> put_resp_header("content-type", "application/json; charset=utf-8")
    |> send_resp(200, Jason.encode!(Hook.ETS.list))
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end
