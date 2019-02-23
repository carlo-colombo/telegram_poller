defmodule TelegramPoller.Hook do
  @moduledoc false

  @derive Jason.Encoder
  defstruct [:token, :url, :timestamp]

  @callback put(String.t, String.t) :: :ok
  @callback list() :: [TelegramPoller.Hook]
end
