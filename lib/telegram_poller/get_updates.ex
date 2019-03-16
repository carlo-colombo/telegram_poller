defmodule TelegramPoller.GetUpdates do
  use GenServer

  require Logger

  alias TelegramPoller.Hook
  alias TelegramPoller.Hook.DynamicSupervisor, as: DS

  @timeout 300
  @max_retries 4

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: via_tuple(arg))
  end

  @impl true
  def init(hook) do
    Logger.info("[#{hook.token}] Init...")
    {:ok, %{hook: hook, offset: 0, conn: nil, response: nil, retries: 0}, {:continue, :first}}
  end

  defp via_tuple(hook) do
    {:via, Registry, {TelegramPoller.Hook.Registry, hook.token, hook}}
  end

  @impl true
  def handle_continue(:retry, %{retries: retries, hook: hook}) when retries > @max_retries do
    Logger.info("[#{hook.token}] Stopping...")

    DS.terminate(self())

    {:stop, "Too many retries(#{@max_retries})", %{}}
  end

  def handle_continue(:retry, state = %{retries: retries}) when retries > 0 do
    delay = 0.5 * (:math.pow(2, retries) - 1)

    Logger.error(fn ->
      "[#{state.hook.token}] Error occurred, retry(#{retries}/#{@max_retries}) in #{delay}s ..."
    end)

    {new, old} =
      Registry.update_value(TelegramPoller.Hook.Registry, state.hook.token, fn hook ->
        update_in(hook.retries, &(&1 + 1))
      end)

    Process.sleep(trunc(delay * 1_000))
    {:noreply, state, {:continue, :more}}
  end

  def handle_continue(_source, state) do
    {:ok, conn} = Mint.HTTP.connect(:https, "api.telegram.org", 443)

    {:ok, conn, request_ref} =
      Mint.HTTP.request(
        conn,
        "GET",
        "/bot#{state.hook.token}/getUpdates?timeout=#{@timeout}&offset=#{state.offset}",
        [],
        nil
      )

    Logger.info(fn ->
      "[#{state.hook.token}] Start long polling for token '#{state.hook.token}', timeout: #{
        @timeout
      }s"
    end)

    state = put_in(state.conn, conn)
    state = put_in(state.response, %{done: false})

    {:noreply, state}
  end

  @impl true
  def handle_info(message, state) do
    case Mint.HTTP.stream(state.conn, message) do
      :unknown ->
        Logger.error(fn ->
          "[#{state.hook.token}] Received unknown message: " <> inspect(message)
        end)

        {:noreply, state}

      {:ok, conn, responses} ->
        state = put_in(state.conn, conn)

        state = Enum.reduce(responses, state, &process_response/2)

        case state.response do
          %{done: true, error: true} ->
            {:noreply, state, {:continue, :retry}}

          %{done: true} ->
            {:noreply, state, {:continue, :more}}

          _ ->
            {:noreply, state}
        end
    end
  end

  defp forward_to_bot(update) do
    Logger.info("message: '#{update["message"]["text"]}', update_id: '#{update["update_id"]}'")
  end

  defp process_response({:status, _request_ref, status}, state) do
    put_in(state.response[:status], status)
  end

  defp process_response({:headers, _request_ref, headers}, state) do
    put_in(state.response[:headers], headers)
  end

  defp process_response({:data, _request_ref, data}, state) do
    update_in(state.response[:data], fn old_data -> (old_data || "") <> data end)
  end

  defp process_response({:done, _request_ref}, state = %{response: %{status: 200}}) do
    updates =
      state.response[:data]
      |> Jason.decode!()
      |> get_in(["result"])

    updates
    |> Task.async_stream(&forward_to_bot/1, ordered: false)
    |> Stream.run()

    Logger.info(fn -> "[#{state.hook.token}] #{updates |> length} updates received" end)

    update_id =
      updates
      |> get_in([at(-1), "update_id"])

    state = put_in(state.offset, if(update_id == nil, do: state.offset, else: update_id + 1))
    state = put_in(state.retries, 0)

    put_in(state.response[:done], true)
  end

  defp process_response({:done, request_ref}, state) do
    state = update_in(state[:retries], fn prev -> (prev || 0) + 1 end)
    state = put_in(state.response[:done], true)
    put_in(state.response[:error], true)
  end

  defp at(index) when is_integer(index) do
    fn op, data, next -> at(op, data, index, next) end
  end

  defp at(:get, data, index, next) when is_list(data) do
    data |> Enum.at(index) |> next.()
  end
end
