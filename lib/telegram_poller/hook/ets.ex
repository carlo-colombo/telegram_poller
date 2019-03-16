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
    hook = %TelegramPoller.Hook{token: token, url: url, timestamp: DateTime.utc_now()}
    :ets.insert(:hook, {token, hook})

    {:ok, pid} =
      DynamicSupervisor.start_child(
        TelegramPoller.GetUpdatesSupervisor,
        {TelegramPoller.GetUpdates, hook}
      )

    :ok
  end

  @impl true
  def list do
    res = :ets.match_object(:hook, {:_, :_})
          |> IO.inspect
    Enum.map(res, &elem(&1, 1))
  end

  @impl
  def report_restart(token) do
    [{_, hook}] = :ets.lookup(:hook, token)
    hook = update_in(hook.restart, &(&1 + 1))
    :ets.insert(:hook, {token, hook})
  end
end
