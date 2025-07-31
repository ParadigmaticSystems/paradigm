defmodule Paradigm.MixProject do
  use Mix.Project

  def project do
    [
      app: :paradigm,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: [
        main: "readme",
        extras: ["README.md"],
        logo: "assets/logo.svg",
        favicon: "assets/favicon.png",
        nest_modules_by_prefix: [Paradigm.Conformance, Paradigm.Graph],
        groups_for_modules: [
          "Paradigm Data Types": [
            Paradigm,
            Paradigm.Class,
            Paradigm.Package,
            Paradigm.PrimitiveType,
            Paradigm.Property,
            Paradigm.Enumeration,
            Paradigm.EnumerationLiteral
          ]
        ]
      ]
    ]
  end

  defp description do
    "A modeling framework for formal abstraction relationships between models and data, supporting multi-layered structures with pluggable graph backends."
  end

  defp package do
    [
      name: "paradigm",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/roriholm/paradigm"},
      maintainers: ["R. Riley Holmes"],
      files: ~w(lib assets .formatter.exs mix.exs README.md LICENSE),
      keywords: ["modeling", "metamodel", "graph", "abstraction", "integration"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end
end
