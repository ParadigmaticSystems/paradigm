defmodule Paradigm.Graph.MapGraphTest do
  use ExUnit.Case
  alias Paradigm.Graph.MapGraph
  alias Paradigm.Graph.Node

  use Paradigm.GraphTestSuite, graph_impl: Paradigm.Graph.MapGraph

  describe "new/1" do
    test "creates a new MapGraph with empty nodes" do
      graph = MapGraph.new()
      assert %MapGraph{nodes: %{}, metadata: []} = graph
    end

    test "creates a new MapGraph with metadata" do
      opts = [name: "test_graph", description: "A test graph"]
      graph = MapGraph.new(opts)

      assert %MapGraph{nodes: %{}, metadata: [name: "test_graph", description: "A test graph"]} =
               graph
    end

    test "filters out unknown options" do
      opts = [name: "test", unknown: "value"]
      graph = MapGraph.new(opts)
      assert %MapGraph{nodes: %{}, metadata: [name: "test"]} = graph
    end
  end

  describe "MapGraph-specific functionality" do
    test "insert_node normalizes atom keys to strings" do
      graph = MapGraph.new()
      node = %Node{id: "test", class: "test_class", data: %{atom_key: "value"}}

      updated_graph = Paradigm.Graph.insert_node(graph, node)
      retrieved_node = Paradigm.Graph.get_node(updated_graph, "test")

      assert retrieved_node.data["atom_key"] == "value"
    end
  end
end
