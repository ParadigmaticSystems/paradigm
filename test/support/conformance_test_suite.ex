defmodule Paradigm.ConformanceTestSuite do
  @moduledoc """
  Complete conformance test suite that can be used with any graph implementation.
  """

  use ExUnit.CaseTemplate

  using(opts) do
    quote do
      use ExUnit.Case

      alias Paradigm.Graph
      alias Paradigm.Graph.Node
      alias Paradigm.Graph.Node.Ref
      alias Paradigm.Conformance

      @graph_impl Keyword.fetch!(unquote(opts), :graph_impl)

      defp new_graph do
        @graph_impl.new()
      end

      defp build_graph(nodes) when is_list(nodes) do
        @graph_impl.new()
        |> Graph.insert_nodes(nodes)
      end

      defp build_graph(node) when is_struct(node, Node) do
        @graph_impl.new()
        |> Graph.insert_node(node)
      end

      # Include all test suites
      use Paradigm.Conformance.TestSuite.BasicGraphFunctions
      use Paradigm.Conformance.TestSuite.BasicValidation
      use Paradigm.Conformance.TestSuite.Multiplicity
      use Paradigm.Conformance.TestSuite.CompositeProperties
      use Paradigm.Conformance.TestSuite.References
    end
  end
end
