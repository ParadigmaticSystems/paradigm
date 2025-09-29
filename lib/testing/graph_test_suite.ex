defmodule Paradigm.GraphTestSuite do
  @moduledoc """
  Complete graph test suite that can be used with any graph implementation.
  """

  use ExUnit.CaseTemplate

  using(opts) do
    quote do
      use ExUnit.Case

      @graph_impl Keyword.fetch!(unquote(opts), :graph_impl)

      defp new_graph do
        @graph_impl.new()
      end

      defp build_graph(nodes) when is_list(nodes) do
        new_graph()
        |> Paradigm.Graph.insert_nodes(nodes)
      end

      defp build_graph(node) when is_struct(node, Paradigm.Graph.Node) do
        new_graph()
        |> Paradigm.Graph.insert_node(node)
      end

      use Paradigm.Graph.TestSuite.BasicGraphFunctions
      use Paradigm.Graph.TestSuite.DiffTests
    end
  end
end
