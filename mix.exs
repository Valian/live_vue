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

          # Tutorials (learning-oriented)
          "guides/installation.md": [title: "Installation"],
          "guides/getting_started.md": [title: "Getting Started"],
          "guides/tutorial.md": [title: "Building Your First App"],

          # How-to Guides (problem-oriented)
          "guides/basic_usage.md": [title: "Basic Usage"],
          "guides/advanced_features.md": [title: "Advanced Features"],
          "guides/deployment.md": [title: "Deployment"],
          "guides/testing.md": [title: "Testing"],
          "guides/troubleshooting.md": [title: "Troubleshooting"],

          # Reference (information-oriented)
          "guides/configuration.md": [title: "Configuration"],
          "guides/client_api.md": [title: "Client-Side API"],
          "guides/component_reference.md": [title: "Component Reference"],

          # Explanation (understanding-oriented)
          "guides/architecture.md": [title: "How LiveVue Works"],
          "guides/faq.md": [title: "FAQ"],
          "guides/comparison.md": [title: "LiveVue vs Alternatives"],
          "CHANGELOG.md": [title: "Changelog"]
        ],
        extra_section: "GUIDES",
        groups_for_extras: [
          Introduction: ["README.md"],
          Tutorials: [
            "guides/installation.md",
            "guides/getting_started.md",
            "guides/tutorial.md"
          ],
          "How-to Guides": [
            "guides/basic_usage.md",
            "guides/advanced_features.md",
            "guides/deployment.md",
            "guides/testing.md",
            "guides/troubleshooting.md"
          ],
          Reference: [
            "guides/configuration.md",
            "guides/client_api.md",
            "guides/component_reference.md"
          ],
          Explanation: [
            "guides/architecture.md",
            "guides/faq.md",
            "guides/comparison.md"
          ],
          Other: ["CHANGELOG.md"]
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
      {:excoveralls, "~> 0.18", only: :test},
      {:makeup_html, "~> 0.1.0", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      docs: ["docs", &copy_images/1],
      setup: ["deps.get", "cmd npm install"],
      "assets.build": ["cmd npm run build"],
      "assets.watch": ["cmd npm run dev"],
      "release.patch": ["assets.build", "expublish.patch --branch=main --disable-publish"],
      "release.minor": ["assets.build", "expublish.minor --branch=main --disable-publish"],
      "release.major": ["assets.build", "expublish.major --branch=main --disable-publish"]
    ]
  end

  defp copy_images(_) do
    File.mkdir_p!("./doc/images")
    File.cp_r("./guides/images", "./doc/images")
  end
end
