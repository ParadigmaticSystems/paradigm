defmodule Paradigm.Conformance.TestSuite.BasicGraphFunctions do
  @moduledoc """
  Basic graph function tests that can be included in conformance test suites.
  """

  defmacro __using__(_opts) do
    quote do
      alias Paradigm.Graph
      alias Paradigm.Graph.Node

      test "get_all_nodes returns empty list for empty graph" do
        graph = new_graph()
        assert Graph.get_all_nodes(graph) == []
      end

      test "insert_node and get_node work correctly" do
        node = %Node{id: "node1", class: "class1", data: %{"prop" => "value"}}
        graph = build_graph(node)

        assert Graph.get_node(graph, "node1") == node
        assert Graph.get_node(graph, "nonexistent") == nil
      end

      test "insert_nodes and get_all_nodes work correctly" do
        nodes = [
          %Node{id: "node1", class: "class1", data: %{"prop" => "value1"}},
          %Node{id: "node2", class: "class2", data: %{"prop" => "value2"}},
          %Node{id: "node3", class: "class1", data: %{"prop" => "value3"}}
        ]

        graph = build_graph(nodes)

        node_ids = Graph.get_all_nodes(graph)
        assert length(node_ids) == 3
        assert "node1" in node_ids
        assert "node2" in node_ids
        assert "node3" in node_ids
      end

      test "get_all_classes returns unique classes" do
        nodes = [
          %Node{id: "node1", class: "class1", data: %{}},
          %Node{id: "node2", class: "class2", data: %{}},
          %Node{id: "node3", class: "class1", data: %{}}
        ]

        graph = new_graph()
                |> Graph.insert_nodes(nodes)

        classes = Graph.get_all_classes(graph)
        assert length(classes) == 2
        assert "class1" in classes
        assert "class2" in classes
      end

      test "get_all_nodes_of_class filters by class correctly" do
        nodes = [
          %Node{id: "node1", class: "class1", data: %{}},
          %Node{id: "node2", class: "class2", data: %{}},
          %Node{id: "node3", class: "class1", data: %{}}
        ]

        graph = new_graph()
                |> Graph.insert_nodes(nodes)

        class1_nodes = Graph.get_all_nodes_of_class(graph, "class1")
        assert length(class1_nodes) == 2
        assert "node1" in class1_nodes
        assert "node3" in class1_nodes

        class2_nodes = Graph.get_all_nodes_of_class(graph, "class2")
        assert class2_nodes == ["node2"]

        # Test with multiple classes
        all_nodes = Graph.get_all_nodes_of_class(graph, ["class1", "class2"])
        assert length(all_nodes) == 3
      end

      test "stream_all_nodes returns enumerable of nodes" do
        nodes = [
          %Node{id: "node1", class: "class1", data: %{"prop" => "value1"}},
          %Node{id: "node2", class: "class2", data: %{"prop" => "value2"}}
        ]

        graph = new_graph()
                |> Graph.insert_nodes(nodes)

        streamed_nodes = graph
                          |> Graph.stream_all_nodes()
                          |> Enum.to_list()

        assert length(streamed_nodes) == 2
        assert Enum.any?(streamed_nodes, &(&1.id == "node1"))
        assert Enum.any?(streamed_nodes, &(&1.id == "node2"))
      end

      test "get_node_data retrieves node data correctly" do
        node = %Node{
          id: "node1",
          class: "class1",
          data: %{"prop1" => "value1", "prop2" => "value2"}
        }

        graph = new_graph()
                |> Graph.insert_node(node)

        assert Graph.get_node_data(graph, "node1", "prop1") == {:ok, "value1"}
        assert Graph.get_node_data(graph, "node1", "nonexistent") == :error
        assert Graph.get_node_data(graph, "nonexistent_node", "prop1") == :error
      end

      test "get_node_data with default returns correctly" do
        node = %Node{
          id: "node1",
          class: "class1",
          data: %{"prop1" => "value1"}
        }

        graph = new_graph()
                |> Graph.insert_node(node)

        assert Graph.get_node_data(graph, "node1", "prop1", "default") == "value1"
        assert Graph.get_node_data(graph, "node1", "nonexistent", "default") == "default"
        assert Graph.get_node_data(graph, "nonexistent_node", "prop1", "default") == "default"
      end

      test "follow_reference works with node references" do
        target_node = %Node{id: "target", class: "class1", data: %{}}
        ref_node = %Node{
          id: "ref_node",
          class: "class2",
          data: %{"ref" => %Paradigm.Graph.Node.Ref{id: "target"}}
        }

        graph = new_graph()
                |> Graph.insert_nodes([target_node, ref_node])

        referenced_node = Graph.follow_reference(graph, "ref_node", "ref")
        assert referenced_node == target_node

        # Test non-existent reference
        assert Graph.follow_reference(graph, "ref_node", "nonexistent") == nil

        # Test non-existent node
        assert Graph.follow_reference(graph, "nonexistent", "ref") == nil
      end
    end
  end
end
