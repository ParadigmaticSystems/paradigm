defmodule FilesystemTest do
  use ExUnit.Case

  describe "filesystem graph adapter" do
    test "filesystem adapter counts test files" do
      filesystem_graph = Paradigm.Graph.FilesystemGraph.new(root: "./test")
      nodes = Paradigm.Graph.get_all_nodes(filesystem_graph)
      assert length(nodes) >= 24
    end

    test "graph instance filesystem adapter is conformant" do
      filesystem_graph = Paradigm.Graph.FilesystemGraph.new(root: ".")
      filesystem_paradigm = Paradigm.Builtin.Filesystem.definition()
      Paradigm.Conformance.assert_conforms(filesystem_graph, filesystem_paradigm)
    end
  end
end
