defmodule TelegramPoller.Hook do
  @moduledoc false

  @derive Jason.Encoder
  defstruct [:token, :url]

  @callback put(String.t, String.t) :: :ok
  @callback list() :: [TelegramPoller.Hook]
end
