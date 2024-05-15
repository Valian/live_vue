defmodule LiveVue.MixProject do
  use Mix.Project

  @version "0.1.0"
  @repo_url "https://github.com/Valian/live_vue"

  def project do
    [
      app: :live_vue,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      preferred_cli_env: [
        "test.watch": :test
      ],

      # Hex
      description: "E2E reactivity for Vue and LiveView",
      package: package(),

      # Docs
      name: "LiveVue",
      docs: [
        name: "LiveVue",
        source_ref: "v#{@version}",
        source_url: @repo_url,
        homepage_url: @repo_url,
        main: "readme",
        extras: ["README.md"],
        links: %{
          "GitHub" => @repo_url
        }
      ]
    ]
  end

  defp package() do
    [
      maintainers: ["Jakub Skalecki"],
      licenses: ["MIT"],
      links: %{
        Changelog: @repo_url <> "/blob/master/CHANGELOG.md",
        GitHub: @repo_url
      },
      files: ~w(priv assets lib mix.exs package.json .formatter.exs LICENSE.md README.md CHANGELOG.md)
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    conditionals =
      case Application.get_env(:live_vue, :ssr_module) do
        # Needed to use :httpc.request
        LiveVue.SSR.ViteJS -> [:inets]
        _ -> []
      end

    [
      extra_applications: [:logger] ++ conditionals
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.2"},
      # Right now it won't work, it require my fork of elixir-nodejs
      # Vite doesn't support CJS anymore for SSR build
      # see PR https://github.com/revelrylabs/elixir-nodejs/pull/84
      # in the meantime I'm trying to become a maintainer of elixir-nodejs
      {:nodejs, "~> 2.0"},
      {:phoenix, ">= 1.7.0"},
      {:phoenix_live_view, ">= 0.18.0"},
      {:telemetry, "~> 0.4 or ~> 1.0"},
      {:esbuild, "~> 0.5", only: :dev},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      "assets.build": [
        "esbuild module",
        "esbuild server",
        "esbuild vite"
      ],
      "assets.watch": [
        "esbuild module --watch",
        "esbuild server --watch",
        "esbuild vite --watch"
      ]
    ]
  end
end
