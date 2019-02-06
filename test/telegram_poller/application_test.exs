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
      assert [%{token: "avalidtoken", url: "http://example.com/foo/bar"}] = Jason.decode!(body, keys: :atoms)
    end

    test "hook are override in subseguent calls if token match" do
      assert {:ok, %{status_code: 201}} =
               HTTPoison.put(
                 "http://localhost:9021/botavalidtoken/setwebhook",
                 Jason.encode!(%{"url" => "http://example.com/foo/bar"}),
                 [{"Content-Type", "application/json"}]
               )

      assert {:ok, %{status_code: 201}} =
               HTTPoison.put(
                 "http://localhost:9021/botavalidtoken/setwebhook",
                 Jason.encode!(%{"url" => "http://example2.com/foo2/bar2"}),
                 [{"Content-Type", "application/json"}]
               )

      assert {:ok, %{body: body}} = HTTPoison.get("http://localhost:9404/api/hooks")
      assert [%{token: "avalidtoken", url: "http://example2.com/foo2/bar2"}] = Jason.decode!(body, keys: :atoms)
    end
  end
end
