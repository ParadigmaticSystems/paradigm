defmodule ParadigmTest do
  use ExUnit.Case
  doctest Paradigm

  describe "high-level paradigm structures" do
    test "embedded metamodel passes invariant check and extracts correctly" do
      paradigm = Paradigm.Canonical.Metamodel.definition()
      paradigm_graph = Paradigm.Abstraction.embed(paradigm)
      # Embedded metamodel conforms to itself (in paradigm form or embedded graph form)
      Paradigm.Conformance.assert_conforms(paradigm_graph, paradigm)
      Paradigm.Conformance.assert_conforms(paradigm_graph, paradigm_graph)
      # Round-tripped Paradigm is equal
      assert paradigm == Paradigm.Abstraction.extract(paradigm_graph)
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
      Paradigm.Conformance.assert_conforms(filesystem_graph, filesystem_paradigm)
    end

    test "bootstrap universe contains self-realizing metamodel" do
      universe = Paradigm.Universe.bootstrap()
      #The bootstrap has performed the conformance test
      assert Paradigm.Universe.all_instantiations_conformant?(universe) == true
      #The metamodel graph has itself as metamodel
      metamodel_id = Paradigm.Universe.find_by_name(universe, "Metamodel")
      paradigm = Paradigm.Universe.get_paradigm_for(universe, metamodel_id)
      assert paradigm == Paradigm.Canonical.Metamodel.definition()
    end

    test "universe propagates along the identity transform" do
      universe = Paradigm.Universe.bootstrap()
      |> Paradigm.Universe.register_transform_by_name(Paradigm.Transform.Identity, "Metamodel", "Metamodel")
      |> Paradigm.Universe.apply_propagate()

      #The identity transform has carried the Metamodel graph to itself
      [{source, destination}] = Paradigm.Universe.get_transform_pairs(universe)
      assert source == destination
      assert source == Paradigm.Universe.find_by_name(universe, "Metamodel")

      #External conformance of Universe
      Paradigm.Conformance.assert_conforms(universe, Paradigm.Canonical.Universe.definition())
    end

  end
end
