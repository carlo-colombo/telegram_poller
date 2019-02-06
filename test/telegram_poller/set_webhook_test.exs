defmodule TelegramPoller.SetWebhookTest do
  use ExUnit.Case, async: true
  doctest TelegramPoller.SetWebhook
  use Plug.Test

  import Mox
  setup :verify_on_exit!

  setup_all do
    :ok
  end

  setup do
    clear_ets()
    on_exit(&clear_ets/0)
  end

  describe "when no previous hook has been registered" do
    test "the endpoint is added to the hooks" do
      conn =
        conn(:put, "/botvalidtoken/setwebhook", %{"url" => "http://example.com/foo/bar"})
        |> TelegramPoller.SetWebhook.call([])

      assert conn.state == :sent
      assert conn.status == 201
    end
  end

  [
    {"invalid path", :put, "/validtoken/setwebhook", 404},
    {"invalid path", :put, "/botavalidtoken/foobar", 404},
    {"invalid path", :put, "/bot1234", 404},
    {"invalid path", :put, "/setweebhook", 404},
    {"method not allowed", :post, "/bot1234/setwebhook", 405},
  ]
  |> Enum.each(fn {desc, method, path, status} ->
    test "status is set to #{status} if #{desc} (#{method} #{path})" do
      conn =
        conn(unquote(method), unquote(path), %{"url" => "http://example.com"})
        |> TelegramPoller.SetWebhook.call([])

      assert conn.state == :sent
      assert conn.status == unquote(status)
    end
  end)

  defp clear_ets, do: :ets.delete_all_objects(:hook)
end
