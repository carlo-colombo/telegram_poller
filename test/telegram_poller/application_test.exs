defmodule TelegramPoller.ApplicationTest do
  use ExUnit.Case, async: false

  alias TelegramPoller.Application

  defp start(context) do
    Application.start(nil, [])
    HTTPoison.start()
    on_exit(fn -> Application.stop([]) end)
    context
  end

  setup :start
  setup context do
    :ets.delete_all_objects(:hook)
    context
  end

  describe "when the hitpoint is hit" do
    test "a webhook is added to the store" do
      assert {:ok, %{status_code: 201}} =
               HTTPoison.put(
                 "http://localhost:9021/botavalidtoken/setwebhook",
                 Jason.encode!(%{"url" => "http://example.com/foo/bar"}),
                 [{"Content-Type", "application/json"}]
               )

      assert {:ok, %{body: body, headers: headers}} = HTTPoison.get("http://localhost:9404/api/hooks")
      assert Enum.member?(headers, {"content-type", "application/json; charset=utf-8"})
      assert [%{token: "avalidtoken", url: "http://example.com/foo/bar", timestamp: timestamp}] = Jason.decode!(body, keys: :atoms)

      assert timestamp != nil
    end

    test "hook are override in subseguent calls if token match" do
      assert {:ok, %{status_code: 201}} =
               HTTPoison.put(
                 "http://localhost:9021/botavalidtoken/setwebhook",
                 Jason.encode!(%{"url" => "http://example.com/foo/bar"}),
                 [{"Content-Type", "application/json"}]
               )
      {:ok, %{body: body}} = HTTPoison.get("http://localhost:9404/api/hooks")
      [%{timestamp: timestamp1}] = Jason.decode!(body, keys: :atoms)

      assert {:ok, %{status_code: 201}} =
               HTTPoison.put(
                 "http://localhost:9021/botavalidtoken/setwebhook",
                 Jason.encode!(%{"url" => "http://example2.com/foo2/bar2"}),
                 [{"Content-Type", "application/json"}]
               )

      assert {:ok, %{body: body}} = HTTPoison.get("http://localhost:9404/api/hooks")
      assert [%{url: "http://example2.com/foo2/bar2", timestamp: timestamp2}] = Jason.decode!(body, keys: :atoms)

      assert timestamp2 > timestamp1
    end

    test "multiple call with different tokens don't override" do
      assert {:ok, %{status_code: 201}} =
               HTTPoison.put(
                 "http://localhost:9021/bottoken1/setwebhook",
                 Jason.encode!(%{"url" => "http://example1.com/token1/bar1"}),
                 [{"Content-Type", "application/json"}]
               )

      assert {:ok, %{status_code: 201}} =
               HTTPoison.put(
                 "http://localhost:9021/bottoken2/setwebhook",
                 Jason.encode!(%{"url" => "http://example2.com/token2/bar2"}),
                 [{"Content-Type", "application/json"}]
               )

      assert {:ok, %{body: body}} = HTTPoison.get("http://localhost:9404/api/hooks")
      assert [
        %{token: "token2", url: "http://example2.com/token2/bar2", timestamp: timestamp2},
        %{token: "token1", url: "http://example1.com/token1/bar1", timestamp: timestamp1},
      ] = Jason.decode!(body, keys: :atoms)

      assert timestamp2 > timestamp1
    end
  end
end
