defmodule UniverseTest do
  use ExUnit.Case

  describe "universe paradigm" do
    test "metamodel conformance" do
      universe_graph =
        Paradigm.Builtin.Universe.definition()
        |> Paradigm.Abstraction.embed()

      Paradigm.Conformance.assert_conforms(
        universe_graph,
        Paradigm.Builtin.Metamodel.definition()
      )
    end

    test "bootstrap contains self-realizing metamodel" do
      universe = Paradigm.Universe.bootstrap()
      # The bootstrap has performed the conformance test
      assert Paradigm.Universe.all_instantiations_conformant?(universe) == true
      # The metamodel graph has itself as metamodel
      metamodel_id = Paradigm.Universe.find_by_name(universe, "Metamodel")
      paradigm = Paradigm.Universe.get_paradigm_for(universe, metamodel_id)
      assert paradigm == Paradigm.Builtin.Metamodel.definition()
    end

    test "propagates along the identity transform" do
      identity_transform =
        Paradigm.Transform.ClassBasedTransform.new()
        |> Paradigm.Transform.ClassBasedTransform.with_default(fn node -> node end)

      universe =
        Paradigm.Universe.bootstrap()
        |> Paradigm.Universe.register_transform_by_name(
          identity_transform,
          "Metamodel",
          "Metamodel"
        )
        |> Paradigm.Universe.apply_propagate()

      # The identity transform has carried the Metamodel graph to itself
      [{source, destination}] = Paradigm.Universe.get_transform_pairs(universe)
      assert source == destination
      assert source == Paradigm.Universe.find_by_name(universe, "Metamodel")

      # External conformance of Universe
      Paradigm.Conformance.assert_conforms(universe, Paradigm.Builtin.Universe.definition())
    end
  end
end
