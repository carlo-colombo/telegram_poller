defmodule TelegramPoller.SetWebhook do
  @moduledoc false

  import Plug.Conn
  alias TelegramPoller.Hook.ETS
  use Plug.Builder
  require Logger


  plug(Plug.Logger)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:extract_token)
  plug(:validate)
  plug(:handle)

  defp extract_token(conn, _opts) do
    case conn.path_info do
      ["bot" <> token, "setwebhook"] -> assign(conn, :token, token)
      _ -> halt(send_resp(conn, 404, ""))
    end
  end

  defp validate(conn = %{method: method}, _opts) when method != "PUT", do: halt(send_resp(conn, 405, ""))
  defp validate(conn, _opts), do: conn

  defp handle(conn = %{assigns: %{token: token}, body_params: %{"url" =>  url}}, _opts) do
    Logger.info "Registering '#{url}' for token '#{token}'"
    ETS.put(token, url)

    send_resp(conn, 201, "")
  end
end
