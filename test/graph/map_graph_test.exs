defmodule Paradigm.Graph.MapGraphTest do
  use ExUnit.Case
  alias Paradigm.Graph.MapGraph
  alias Paradigm.Graph.Node

  use Paradigm.ConformanceTestSuite, graph_impl: Paradigm.Graph.MapGraph

  describe "new/1" do
    test "creates a new MapGraph with empty nodes" do
      graph = MapGraph.new()
      assert %MapGraph{nodes: %{}, metadata: []} = graph
    end

    test "creates a new MapGraph with metadata" do
      opts = [name: "test_graph", description: "A test graph"]
      graph = MapGraph.new(opts)
      assert %MapGraph{nodes: %{}, metadata: [name: "test_graph", description: "A test graph"]} = graph
    end

    test "filters out unknown options" do
      opts = [name: "test", unknown: "value"]
      graph = MapGraph.new(opts)
      assert %MapGraph{nodes: %{}, metadata: [name: "test"]} = graph
    end
  end

  describe "Paradigm.Graph implementation" do
    setup do
      node1 = %Node{id: "node1", class: "person", data: %{name: "Alice", age: 30}}
      node2 = %Node{id: "node2", class: "person", data: %{name: "Bob", age: 25}}
      node3 = %Node{id: "node3", class: "company", data: %{name: "Acme Corp"}}

      graph = MapGraph.new()
      |> Paradigm.Graph.insert_nodes([node1, node2, node3])

      {:ok, graph: graph, node1: node1, node2: node2, node3: node3}
    end

    test "get_all_nodes returns all node ids", %{graph: graph} do
      node_ids = Paradigm.Graph.get_all_nodes(graph)
      assert Enum.sort(node_ids) == ["node1", "node2", "node3"]
    end

    test "get_all_classes returns unique classes", %{graph: graph} do
      classes = Paradigm.Graph.get_all_classes(graph)
      assert Enum.sort(classes) == ["company", "person"]
    end

    test "get_node returns specific node", %{graph: graph} do
      node = Paradigm.Graph.get_node(graph, "node1")
      assert node.id == "node1"
      assert node.class == "person"
      assert node.data["name"] == "Alice"
    end

    test "get_node returns nil for non-existent node", %{graph: graph} do
      node = Paradigm.Graph.get_node(graph, "non_existent")
      assert node == nil
    end

    test "stream_all_nodes returns a stream of nodes", %{graph: graph} do
      nodes = Paradigm.Graph.stream_all_nodes(graph) |> Enum.to_list()
      assert length(nodes) == 3
      node_ids = Enum.map(nodes, & &1.id) |> Enum.sort()
      assert node_ids == ["node1", "node2", "node3"]
    end

    test "insert_node adds a single node" do
      graph = MapGraph.new()
      node = %Node{id: "test", class: "test_class", data: %{key: "value"}}

      updated_graph = Paradigm.Graph.insert_node(graph, node)
      retrieved_node = Paradigm.Graph.get_node(updated_graph, "test")

      assert retrieved_node.id == "test"
      assert retrieved_node.class == "test_class"
      assert retrieved_node.data["key"] == "value"
    end

    test "insert_node normalizes atom keys to strings" do
      graph = MapGraph.new()
      node = %Node{id: "test", class: "test_class", data: %{atom_key: "value"}}

      updated_graph = Paradigm.Graph.insert_node(graph, node)
      retrieved_node = Paradigm.Graph.get_node(updated_graph, "test")

      assert retrieved_node.data["atom_key"] == "value"
    end

    test "insert_nodes adds multiple nodes" do
      graph = MapGraph.new()
      nodes = [
        %Node{id: "test1", class: "test", data: %{name: "Test 1"}},
        %Node{id: "test2", class: "test", data: %{name: "Test 2"}}
      ]

      updated_graph = Paradigm.Graph.insert_nodes(graph, nodes)

      assert Paradigm.Graph.get_node(updated_graph, "test1").data["name"] == "Test 1"
      assert Paradigm.Graph.get_node(updated_graph, "test2").data["name"] == "Test 2"
    end

    test "get_all_nodes_of_class with single class", %{graph: graph} do
      person_nodes = Paradigm.Graph.get_all_nodes_of_class(graph, "person")
      assert Enum.sort(person_nodes) == ["node1", "node2"]

      company_nodes = Paradigm.Graph.get_all_nodes_of_class(graph, "company")
      assert company_nodes == ["node3"]
    end

    test "get_all_nodes_of_class with multiple classes", %{graph: graph} do
      all_nodes = Paradigm.Graph.get_all_nodes_of_class(graph, ["person", "company"])
      assert Enum.sort(all_nodes) == ["node1", "node2", "node3"]

      person_nodes = Paradigm.Graph.get_all_nodes_of_class(graph, ["person"])
      assert Enum.sort(person_nodes) == ["node1", "node2"]
    end

    test "get_all_nodes_of_class with non-existent class", %{graph: graph} do
      nodes = Paradigm.Graph.get_all_nodes_of_class(graph, "non_existent")
      assert nodes == []
    end

    test "get_node_data returns node data", %{graph: graph} do
      {:ok, name} = Paradigm.Graph.get_node_data(graph, "node1", "name")
      assert name == "Alice"

      {:ok, age} = Paradigm.Graph.get_node_data(graph, "node1", "age")
      assert age == 30
    end

    test "get_node_data returns default for non-existent key", %{graph: graph} do
      value = Paradigm.Graph.get_node_data(graph, "node1", "non_existent")
      assert value == :error

      value_with_default = Paradigm.Graph.get_node_data(graph, "node1", "non_existent", "default")
      assert value_with_default == "default"
    end

    test "get_node_data returns default for non-existent node", %{graph: graph} do
      value = Paradigm.Graph.get_node_data(graph, "non_existent", "name")
      assert value == :error

      value_with_default = Paradigm.Graph.get_node_data(graph, "non_existent", "name", "default")
      assert value_with_default == "default"
    end

    test "follow_reference follows node references" do
      ref_node = %Node{id: "ref_target", class: "target", data: %{name: "Target"}}
      node_with_ref = %Node{id: "with_ref", class: "referrer", data: %{ref: %Node.Ref{id: "ref_target"}}}

      graph = MapGraph.new()
      |> Paradigm.Graph.insert_nodes([ref_node, node_with_ref])

      referenced_node = Paradigm.Graph.follow_reference(graph, "with_ref", "ref")
      assert referenced_node.id == "ref_target"
      assert referenced_node.data["name"] == "Target"
    end

    test "follow_reference returns nil for non-existent reference" do
      node = %Node{id: "test", class: "test", data: %{}}
      graph = MapGraph.new() |> Paradigm.Graph.insert_node(node)

      result = Paradigm.Graph.follow_reference(graph, "test", "non_existent")
      assert result == nil
    end

    test "follow_reference returns nil for non-existent target" do
      node_with_ref = %Node{id: "with_ref", class: "referrer", data: %{ref: %Node.Ref{id: "non_existent"}}}
      graph = MapGraph.new() |> Paradigm.Graph.insert_node(node_with_ref)

      result = Paradigm.Graph.follow_reference(graph, "with_ref", "ref")
      assert result == nil
    end
  end
end
