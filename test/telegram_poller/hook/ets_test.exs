defmodule TelegramPoller.Hook.ETSTest do
  use ExUnit.Case
  alias TelegramPoller.Hook.ETS

  defp reset(ctx) do
    :ets.delete_all_objects(:hook)
    ctx
  end

  setup :reset

  test "when put a webhook it shows when listing the hooks" do
    ETS.put("a_new_token", "http://www.example.com")

    assert [%{token: "a_new_token", url: "http://www.example.com"}] = ETS.list()
  end
end
