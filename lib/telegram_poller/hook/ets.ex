defmodule TelegramPoller.Hook.ETS do
  @moduledoc false
  use GenServer
  @behaviour TelegramPoller.Hook

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default)
  end

  @impl true
  def init(_) do
    :ets.new(:hook, [:named_table, :public, read_concurrency: true])
    {:ok, :hook}
  end

  @impl true
  def put(token, url) do
    :ets.insert(:hook, {token, %TelegramPoller.Hook{token: token, url: url}})
    :ok
  end

  @impl true
  def list do
    res = :ets.match_object(:hook, {:_, :_})
    Enum.map(res, &elem(&1, 1))
  end
end
