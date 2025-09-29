defmodule BuiltinsTest do
  use ExUnit.Case

  describe "metamodel paradigm" do
    test "embeds, passes invariant check and extracts correctly" do
      paradigm = Paradigm.Builtin.Metamodel.definition()
      paradigm_graph = Paradigm.Abstraction.embed(paradigm)
      # Embedded metamodel conforms to itself (in paradigm form or embedded graph form)
      Paradigm.Conformance.assert_conforms(paradigm_graph, paradigm)
      Paradigm.Conformance.assert_conforms(paradigm_graph, paradigm_graph)
      # Round-tripped Paradigm is equal
      assert paradigm == Paradigm.Abstraction.extract(paradigm_graph)
    end

    test "identity transform is applied" do
      paradigm = Paradigm.Builtin.Metamodel.definition()
      graph = Paradigm.Abstraction.embed(paradigm)

      {:ok, transformed_graph} =
        Paradigm.Transform.Identity.transform(
          graph,
          Paradigm.Graph.MapGraph.new(graph.metadata),
          %{}
        )

      assert graph == transformed_graph
    end
  end
end
