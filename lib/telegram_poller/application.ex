defmodule TelegramPoller.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: TelegramPoller.SetWebhook,
        options: [port: 9021]
      ),
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: TelegramPoller.Admin,
        options: [port: 9404]
      ),
      TelegramPoller.Hook.ETS
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TelegramPoller.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
