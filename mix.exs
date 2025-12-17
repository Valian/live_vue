defmodule LiveVue.MixProject do
  use Mix.Project

  @version "1.0.0-rc.4"
  @repo_url "https://github.com/Valian/live_vue"

  def project do
    [
      app: :live_vue,
      version: @version,
      consolidate_protocols: Mix.env() != :test,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      listeners: listeners(Mix.env()),
      aliases: aliases(),
      deps: deps(),

      # Hex
      description: "E2E reactivity for Vue and LiveView",
      package: package(),

      # Docs
      name: "LiveVue",
      docs: [
        name: "LiveVue",
        logo: "live_vue_logo_rounded.png",
        source_ref: "v#{@version}",
        source_url: @repo_url,
        homepage_url: @repo_url,
        main: "readme",
        extras: [
          "README.md": [title: "LiveVue"],

          # Getting Started
          "guides/installation.md": [title: "Installation"],
          "guides/getting_started.md": [title: "Getting Started"],

          # Core Usage
          "guides/basic_usage.md": [title: "Basic Usage"],
          "guides/forms.md": [title: "Forms and Validation"],
          "guides/configuration.md": [title: "Configuration"],

          # Reference
          "guides/component_reference.md": [title: "Component Reference"],
          "guides/client_api.md": [title: "Client-Side API"],

          # Advanced Topics
          "guides/architecture.md": [title: "How LiveVue Works"],
          "guides/testing.md": [title: "Testing"],
          "guides/deployment.md": [title: "Deployment"],

          # Help & Troubleshooting
          "guides/faq.md": [title: "FAQ"],
          "guides/troubleshooting.md": [title: "Troubleshooting"],
          "guides/comparison.md": [title: "LiveVue vs Alternatives"],
          "CHANGELOG.md": [title: "Changelog"]
        ],
        extra_section: "GUIDES",
        groups_for_extras: [
          Introduction: ["README.md"],
          "Getting Started": [
            "guides/installation.md",
            "guides/getting_started.md"
          ],
          "Core Usage": [
            "guides/basic_usage.md",
            "guides/forms.md",
            "guides/configuration.md"
          ],
          Reference: [
            "guides/component_reference.md",
            "guides/client_api.md"
          ],
          "Advanced Topics": [
            "guides/architecture.md",
            "guides/testing.md",
            "guides/deployment.md"
          ],
          "Help & Troubleshooting": [
            "guides/faq.md",
            "guides/troubleshooting.md",
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

  def cli do
    [
      preferred_envs: [
        precommit: :test,
        "test.watch": :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  defp package do
    [
      maintainers: ["Jakub Skalecki"],
      licenses: ["MIT"],
      links: %{
        Changelog: @repo_url <> "/blob/master/CHANGELOG.md",
        GitHub: @repo_url
      },
      files: ~w(assets/js/live_vue lib mix.exs package.json .formatter.exs LICENSE.md README.md CHANGELOG.md usage-rules.md)
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

  defp elixirc_paths(:e2e), do: ["lib", "test/e2e/features"]
  defp elixirc_paths(_), do: ["lib"]

  defp listeners(:e2e), do: [Phoenix.CodeReloader]
  defp listeners(_), do: []

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.2"},
      {:nodejs, "~> 3.1"},
      {:phoenix, ">= 1.7.0"},
      {:phoenix_live_view, ">= 0.18.0"},
      {:telemetry, "~> 0.4 or ~> 1.0"},
      {:jsonpatch, "~> 2.3"},
      {:igniter, "~> 0.6", optional: true},
      {:phoenix_vite, "~> 0.4"},
      {:lazy_html, ">= 0.1.0", optional: true},
      {:ecto, "~> 3.0", optional: true},
      {:phoenix_ecto, "~> 4.0", optional: true},

      # dev dependencies
      {:ex_doc, "~> 0.38", only: :dev, runtime: false, warn_if_outdated: true},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:expublish, "~> 2.5", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:makeup_html, "~> 0.1.0", only: :dev, runtime: false},
      {:styler, "~> 1.5", only: [:dev, :test], runtime: false},

      # e2e dependencies
      {:bandit, "~> 1.5", only: :e2e},
      {:phoenix_live_reload, "~> 1.2", only: :e2e}
    ]
  end

  defp aliases do
    [
      docs: ["docs", &copy_images/1],
      setup: ["deps.get", "cmd npm install"],
      precommit: ["test", "format", "e2e.test", "assets.test"],
      "assets.test": ["cmd npm test"],
      "e2e.test": ["cmd npm run e2e:test"],
      "release.patch": ["expublish.patch --branch=main --disable-publish"],
      "release.minor": ["expublish.minor --branch=main --disable-publish"],
      "release.major": ["expublish.major --branch=main --disable-publish"]
    ]
  end

  defp copy_images(_) do
    File.mkdir_p!("./doc/images")
    File.cp_r("./guides/images", "./doc/images")
  end
end
