defmodule CAStore.MixProject do
  use Mix.Project

  @repo_url "https://github.com/elixir-mint/castore"

  def project do
    [
      app: :castore,
      version: version(),
      elixir: "~> 1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      xref: [exclude: [:public_key]],

      # Hex
      package: package(),
      description: "Up-to-date CA certificate store.",

      # Docs
      name: "CAStore",
      docs: [
        source_ref: "v#{version()}",
        source_url: @repo_url
      ]
    ]
  end

  def application do
    [
      extra_applications: extra_applications(Mix.env())
    ]
  end

  defp extra_applications(:prod), do: [:logger]
  defp extra_applications(_env), do: [:public_key] ++ extra_applications(:prod)

  defp deps do
    [
      {:ex_doc, "~> 0.29", only: :dev}
    ]
  end

  defp package do
    [
      files: ["lib/castore.ex", "priv", "mix.exs", "README.md", "VERSION"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @repo_url}
    ]
  end

  defp version do
    "VERSION"
    |> File.read!()
    |> String.trim()
  end
end
