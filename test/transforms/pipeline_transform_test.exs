defmodule PipelineTransformTest do
  use ExUnit.Case

  setup do
    paradigm = Paradigm.Builtin.Metamodel.definition()
    graph = Paradigm.Abstraction.embed(paradigm)

    {:ok, graph: graph}
  end

  test "Many ways to do nothing", %{graph: graph} do
    non_transform = fn source, _ -> {:ok, source} end

    identity_fn_transform = fn source, target ->
      result =
        Paradigm.Graph.stream_all_nodes(source)
        |> Enum.reduce(target, fn node, acc_target ->
          Paradigm.Graph.insert_node(acc_target, node)
        end)

      {:ok, result}
    end

    identity_class_transform =
      Paradigm.ClassBasedTransform.new()
      |> Paradigm.ClassBasedTransform.with_default(fn node -> node end)

    pipeline = [non_transform, identity_fn_transform, identity_class_transform]

    pipeline_transform =
      Paradigm.PipelineTransform.new(pipeline)

    {:ok, transformed_graph} =
      Paradigm.Transform.transform(pipeline_transform, graph, Paradigm.Graph.MapGraph.new(), [])

    assert graph.nodes == transformed_graph.nodes
  end
end
