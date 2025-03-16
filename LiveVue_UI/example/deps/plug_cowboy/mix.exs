defmodule Plug.Cowboy.MixProject do
  use Mix.Project

  @source_url "https://github.com/elixir-plug/plug_cowboy"
  @version "2.7.3"
  @description "A Plug adapter for Cowboy"

  def project do
    [
      app: :plug_cowboy,
      version: @version,
      elixir: "~> 1.11",
      deps: deps(),
      package: package(),
      description: @description,
      name: "Plug.Cowboy",
      docs: [
        main: "Plug.Cowboy",
        source_ref: "v#{@version}",
        source_url: @source_url,
        extras: ["CHANGELOG.md"]
      ],
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Plug.Cowboy, []}
    ]
  end

  def deps do
    [
      {:plug, "~> 1.14"},
      {:cowboy, "~> 2.7"},
      {:cowboy_telemetry, "~> 0.3"},
      {:ex_doc, "~> 0.20", only: :docs},
      {:hackney, "~> 1.2", only: :test},
      {:x509, "~> 0.6", only: :test}
    ]
  end

  defp package do
    %{
      licenses: ["Apache-2.0"],
      maintainers: ["José Valim", "Gary Rennie"],
      links: %{"GitHub" => @source_url}
    }
  end

  defp aliases do
    [
      test: ["x509.gen.suite -f -p cowboy -o test/fixtures/ssl", "test"]
    ]
  end
end
