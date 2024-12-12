defmodule LiveVue.MixProject do
  use Mix.Project

  @version "0.5.7"
  @repo_url "https://github.com/Valian/live_vue"

  def project do
    [
      app: :live_vue,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      preferred_cli_env: [
        "test.watch": :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
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
        extras: [
          "README.md": [title: "LiveVue"],
          "guides/installation.md": [title: "Installation"],
          "guides/getting_started.md": [title: "Getting Started"],
          "guides/basic_usage.md": [title: "Basic Usage"],
          "guides/advanced_features.md": [title: "Advanced Features"],
          "guides/deployment.md": [title: "Deployment"],
          "guides/testing.md": [title: "Testing Guide"],
          "guides/faq.md": [title: "FAQ"],
          "CHANGELOG.md": [title: "Changelog"]
        ],
        extra_section: "GUIDES",
        groups_for_extras: [
          Introduction: ["README.md", "guides/installation.md"],
          Guides: Path.wildcard("guides/*.md") |> Enum.reject(&(&1 == "guides/faq.md"))
        ],
        links: %{
          "GitHub" => @repo_url
        }
      ],
      test_coverage: [tool: ExCoveralls]
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
      files: ~w(priv/static assets/copy lib mix.exs package.json .formatter.exs LICENSE.md README.md CHANGELOG.md)
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
      {:nodejs, "~> 3.1"},
      {:phoenix, ">= 1.7.0"},
      {:phoenix_live_view, ">= 0.18.0"},
      {:floki, ">= 0.30.0", optional: true},
      {:telemetry, "~> 0.4 or ~> 1.0"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:expublish, "~> 2.5", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "cmd npm install"],
      "assets.build": ["cmd npm run build"],
      "assets.watch": ["cmd npm run dev"],
      "release.patch": ["assets.build", "expublish.patch --branch=main --disable-publish"],
      "release.minor": ["assets.build", "expublish.minor --branch=main --disable-publish"],
      "release.major": ["assets.build", "expublish.major --branch=main --disable-publish"]
    ]
  end
end
