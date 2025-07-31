defmodule ParadigmTest do
  use ExUnit.Case
  doctest Paradigm

  describe "high-level paradigm structures" do
    test "embedded metamodel passes invariant check and extracts correctly" do
      paradigm = Paradigm.Canonical.Metamodel.definition()
      graph_instance = Paradigm.Abstraction.embed(paradigm, Paradigm.Graph.MapImpl)

      assert Paradigm.Conformance.check_graph(paradigm, graph_instance) ==
               %Paradigm.Conformance.Result{issues: []}

      new_paradigm = Paradigm.Abstraction.extract(graph_instance)
      assert paradigm == new_paradigm
    end

    test "identity transform is applied" do
      paradigm = Paradigm.Canonical.Metamodel.definition()
      graph_instance = Paradigm.Abstraction.embed(paradigm, Paradigm.Graph.MapImpl)

      {:ok, transformed_graph} =
        Paradigm.Transform.Identity.transform(graph_instance, Paradigm.Graph.MapImpl, %{})

      assert graph_instance == transformed_graph
    end
  end
end
