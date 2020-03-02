defmodule TelegramPoller.MixProject do
  use Mix.Project

  def project do
    [
      app: :telegram_poller,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {TelegramPoller.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.0"},
      {:jason, "~> 1.1"},
      {:httpoison, "~> 1.5", override: true},
      {:mint, "~> 0.1.0"},
      {:castore, "~> 0.1.0"},
      {:bypass, "~> 1.0", only: :test},
      {:exsync, "~> 0.2", only: :dev},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      {:credo, "~> 1.2.3", only: [:dev, :test], runtime: false},
      {:mox, "~> 0.4.0", only: :test},
      {:distillery, "~> 2.0"}
    ]
  end
end
