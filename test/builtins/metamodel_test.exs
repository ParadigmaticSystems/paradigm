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
  end
end
