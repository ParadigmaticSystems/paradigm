defmodule Paradigm.MixProject do
  use Mix.Project

  def project do
    [
      app: :paradigm,
      version: "0.3.0",
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
        nest_modules_by_prefix: [
          Paradigm.Graph,
          Paradigm.Transform,
          Paradigm.Conformance,
          Paradigm.Builtin
        ],
        groups_for_modules: [
          "Paradigm Data Types": [
            Paradigm,
            Paradigm.Class,
            Paradigm.Package,
            Paradigm.PrimitiveType,
            Paradigm.Property,
            Paradigm.Enumeration,
            Paradigm.EnumerationLiteral
          ],
          Testing: [
            Paradigm.Conformance.TestSuite,
            Paradigm.Conformance.TestSuite.BasicValidation,
            Paradigm.Conformance.TestSuite.CompositeProperties,
            Paradigm.Conformance.TestSuite.Multiplicity,
            Paradigm.Conformance.TestSuite.References,
            Paradigm.Graph.TestSuite,
            Paradigm.Graph.TestSuite.BasicGraphFunctions,
            Paradigm.Graph.TestSuite.DiffTests
          ],
          "Graph Implementations": [
            Paradigm.Graph.MapGraph,
            Paradigm.Graph.GitRepoGraph,
            Paradigm.Graph.FilesystemGraph
          ]
        ]
      ]
    ]
  end

  defp description do
    "A model management framework supporting multi-layered abstraction structures, pluggable data layers, and arbitrary command-line transform tools."
  end

  defp package do
    [
      name: "paradigm",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/ParadigmaticSystems/paradigm"},
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
