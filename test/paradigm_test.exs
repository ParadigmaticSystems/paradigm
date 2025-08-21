defmodule ParadigmTest do
  use ExUnit.Case
  doctest Paradigm

  describe "high-level paradigm structures" do
    test "embedded metamodel passes invariant check and extracts correctly" do
      paradigm = Paradigm.Canonical.Metamodel.definition()
      paradigm_graph = Paradigm.Abstraction.embed(paradigm)

      assert Paradigm.Conformance.check_graph(paradigm, paradigm_graph) ==
               %Paradigm.Conformance.Result{issues: []}

      new_paradigm = Paradigm.Abstraction.extract(paradigm_graph)
      assert paradigm == new_paradigm
    end

    test "identity transform is applied" do
      paradigm = Paradigm.Canonical.Metamodel.definition()
      graph = Paradigm.Abstraction.embed(paradigm)

      {:ok, transformed_graph} =
        Paradigm.Transform.Identity.transform(graph, Paradigm.Graph.MapGraph.new(graph.metadata), %{})

      assert graph == transformed_graph
    end

    test "filesystem adapter counts test files" do
      filesystem_graph = Paradigm.Graph.FilesystemGraph.new(root: "./test")
      nodes = Paradigm.Graph.get_all_nodes(filesystem_graph)
      assert length(nodes) == 4
    end

    test "graph instance filesystem adapter is conformant" do
      filesystem_graph = Paradigm.Graph.FilesystemGraph.new(root: ".")
      filesystem_paradigm = Paradigm.Canonical.Filesystem.definition()
      assert %Paradigm.Conformance.Result{issues: []} = Paradigm.Conformance.check_graph(filesystem_paradigm, filesystem_graph)
    end

    test "bootstrap universe" do
      bootstrap_universe_graph = Paradigm.Universe.bootstrap()
      [ metamodel_id ] = Paradigm.Graph.get_all_nodes_of_class(bootstrap_universe_graph, "registered_graph")
      paradigm = Paradigm.Universe.get_paradigm_for(bootstrap_universe_graph, metamodel_id)
      assert paradigm == Paradigm.Canonical.Metamodel.definition()
    end

    test "universe example" do
      bootstrap_universe_graph = Paradigm.Universe.bootstrap()
      metamodel_id = Paradigm.Universe.find_by_name(bootstrap_universe_graph, "Metamodel")

      universe_instance = bootstrap_universe_graph |> Paradigm.Universe.register_transform(Paradigm.Transform.Identity, metamodel_id, metamodel_id)
      assert Paradigm.Graph.get_node(universe_instance, "#{metamodel_id}_#{metamodel_id}").data["conformance_result"] == nil

      transformed_universe = Paradigm.Universe.apply_propagate(universe_instance)

      #The transform has performed the conformance test:
      assert Paradigm.Graph.get_node(transformed_universe, "#{metamodel_id}_#{metamodel_id}").data["conformance_result"].issues == []
      [transform_instance] = Paradigm.Graph.get_all_nodes_of_class(transformed_universe, "transform_instance")
      |> Enum.map(&Paradigm.Graph.get_node(transformed_universe, &1))
      assert transform_instance.data["source"].id == metamodel_id
      assert transform_instance.data["target"].id == metamodel_id

      universe_paradigm = Paradigm.Canonical.Universe.definition()
      assert %Paradigm.Conformance.Result{issues: []} = Paradigm.Conformance.check_graph(universe_paradigm, transformed_universe)
    end

  end
end
