defmodule ClassBasedTransformTest do
  use ExUnit.Case

  setup do
    paradigm = Paradigm.Builtin.Metamodel.definition()
    graph = Paradigm.Abstraction.embed(paradigm)

    {:ok, graph: graph}
  end

  test "empty transform", %{graph: graph} do
    empty_transform =
      Paradigm.ClassBasedTransform.new()
      # Redundant
      |> Paradigm.ClassBasedTransform.with_default(fn _ -> [] end)

    {:ok, transformed_graph} =
      Paradigm.Transform.transform(empty_transform, graph, Paradigm.Graph.MapGraph.new())

    assert transformed_graph.nodes == %{}
  end

  test "identity transform copies graph", %{graph: graph} do
    identity_transform =
      Paradigm.ClassBasedTransform.new()
      |> Paradigm.ClassBasedTransform.with_default(fn node -> node end)

    {:ok, transformed_graph} =
      Paradigm.Transform.transform(identity_transform, graph, Paradigm.Graph.MapGraph.new())

    assert graph.nodes == transformed_graph.nodes
  end

  test "copy out a subset of nodes and capitalize their IDs", %{graph: graph} do
    primitives_grabber =
      Paradigm.ClassBasedTransform.new()
      |> Paradigm.ClassBasedTransform.for_class("primitive_type", fn node ->
        %{node | id: String.upcase(node.id)}
      end)

    {:ok, transformed_graph} =
      Paradigm.Transform.transform(primitives_grabber, graph, Paradigm.Graph.MapGraph.new())

    assert Paradigm.Graph.get_all_nodes(transformed_graph) == ["BOOLEAN", "INTEGER", "STRING"]
  end
end
