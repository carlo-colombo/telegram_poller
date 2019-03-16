defmodule TelegramPoller.Hook.DynamicSupervisor do
  @moduledoc false
  use GenServer
  @behaviour TelegramPoller.Hook

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default)
  end

  @impl true
  def init(_) do
  end

  @impl true
  def put(token, url) do
    hook = %TelegramPoller.Hook{token: token, url: url, timestamp: DateTime.utc_now()}

    case DynamicSupervisor.start_child(
           TelegramPoller.GetUpdatesSupervisor,
           {TelegramPoller.GetUpdates, hook}
         ) do
      {:ok, _} ->
        :ok

      {:error, {:already_started, pid}} ->
        terminate(pid)
        put(token, url)
    end
  end

  @impl true
  def list do
    children
    |> Enum.map(&elem(&1, 1))
    |> Enum.map(&Registry.keys(TelegramPoller.Hook.Registry, &1))
    |> List.flatten()
    |> Enum.map(&Registry.lookup(TelegramPoller.Hook.Registry, &1))
    |> List.flatten()
    |> Enum.map(&elem(&1, 1))
  end

  def terminate(pid) do
    DynamicSupervisor.terminate_child(TelegramPoller.GetUpdatesSupervisor, pid)
  end

  def children, do: DynamicSupervisor.which_children(TelegramPoller.GetUpdatesSupervisor)

  def kill_all do
    children
    |> Enum.map(
      &DynamicSupervisor.terminate_child(TelegramPoller.GetUpdatesSupervisor, elem(&1, 1))
    )
  end
end
