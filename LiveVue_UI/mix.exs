defmodule LiveVueUI.MixProject do
  use Mix.Project

  @version "0.1.0"
  @description "A comprehensive UI component library built on top of LiveVue"
  @source_url "https://github.com/yourusername/live_vue_ui"

  def project do
    [
      app: :live_vue_ui,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: @description,
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:phoenix_live_view, "~> 0.20.0"},
      {:live_vue, "~> 0.5.0"},
      {:jason, "~> 1.0"},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Your Name"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      extras: ["README.md"],
      groups_for_modules: []
    ]
  end
end
