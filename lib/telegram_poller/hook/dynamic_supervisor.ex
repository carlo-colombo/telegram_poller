defmodule TelegramPoller.Hook.DynamicSupervisor do
  @moduledoc false
  @behaviour TelegramPoller.Hook

  @registry TelegramPoller.Hook.Registry
  @supervisor TelegramPoller.GetUpdatesSupervisor

  @impl true
  def put(token, url) do
    hook = %TelegramPoller.Hook{token: token, url: url, timestamp: DateTime.utc_now()}

    case DynamicSupervisor.start_child(@supervisor, {TelegramPoller.GetUpdates, hook}) do
      {:ok, _} ->
        :ok

      {:error, {:already_started, pid}} ->
        stop(pid)
        put(token, url)
    end
  end

  @impl true
  def list do
    children()
    |> Enum.map(&elem(&1, 1))
    |> Enum.map(&Registry.keys(@registry, &1))
    |> List.flatten()
    |> Enum.map(&Registry.lookup(@registry, &1))
    |> List.flatten()
    |> Enum.map(&elem(&1, 1))
  end

  @impl true
  def stop(pid), do: DynamicSupervisor.terminate_child(@supervisor, pid)

  @impl true
  def stop_all do
    children()
    |> Enum.map(&stop(elem(&1, 1)))
  end

  defp children, do: DynamicSupervisor.which_children(@supervisor)
end
