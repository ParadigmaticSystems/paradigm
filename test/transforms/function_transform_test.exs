defmodule FunctionTransformTest do
  use ExUnit.Case

  setup do
    paradigm = Paradigm.Builtin.Metamodel.definition()
    graph = Paradigm.Abstraction.embed(paradigm)

    {:ok, graph: graph}
  end

  test "non-transform returns original graph", %{graph: graph} do
    non_transform = fn source, _ -> {:ok, source} end

    {:ok, transformed_graph} =
      Paradigm.Transform.transform(non_transform, graph, %{})

    assert graph == transformed_graph
  end

  test "transform can be specified for particular graph", %{graph: graph} do
    bad_transform = fn
      %Paradigm.Graph.FilesystemGraph{}, _ -> {:ok, :but_not_really}
      _, _ -> {:error, "This transform only works on filesystem graphs."}
    end

    {:error, "This transform only works on filesystem graphs."} =
      Paradigm.Transform.transform(bad_transform, graph, %{})
  end

  test "identity transform copies graph", %{graph: graph} do
    identity_transform = fn source, target ->
      result =
        Paradigm.Graph.stream_all_nodes(source)
        |> Enum.reduce(target, fn node, acc_target ->
          Paradigm.Graph.insert_node(acc_target, node)
        end)

      {:ok, result}
    end

    {:ok, transformed_graph} =
      Paradigm.Transform.transform(identity_transform, graph, Paradigm.Graph.MapGraph.new(), [])

    assert graph.nodes == transformed_graph.nodes
  end
end
