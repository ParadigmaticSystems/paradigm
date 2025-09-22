defmodule Paradigm.Graph.TestSuite.BasicGraphFunctions do
  @moduledoc """
  Basic graph function tests that can be included in conformance test suites.
  """

  defmacro __using__(_opts) do
    quote do
      test "get_all_nodes returns empty list for empty graph" do
        graph = new_graph()
        assert Paradigm.Graph.get_all_nodes(graph) == []
      end

      test "insert_node and get_node work correctly" do
        node = %Paradigm.Graph.Node{id: "node1", class: "class1", data: %{"prop" => "value"}}
        graph = build_graph(node)

        assert Paradigm.Graph.get_node(graph, "node1") == node
        assert Paradigm.Graph.get_node(graph, "nonexistent") == nil
      end

      test "insert_nodes and get_all_nodes work correctly" do
        nodes = [
          %Paradigm.Graph.Node{id: "node1", class: "class1", data: %{"prop" => "value1"}},
          %Paradigm.Graph.Node{id: "node2", class: "class2", data: %{"prop" => "value2"}},
          %Paradigm.Graph.Node{id: "node3", class: "class1", data: %{"prop" => "value3"}}
        ]

        graph = build_graph(nodes)

        node_ids = Paradigm.Graph.get_all_nodes(graph)
        assert length(node_ids) == 3
        assert "node1" in node_ids
        assert "node2" in node_ids
        assert "node3" in node_ids
      end

      test "get_all_classes returns unique classes" do
        nodes = [
          %Paradigm.Graph.Node{id: "node1", class: "class1", data: %{}},
          %Paradigm.Graph.Node{id: "node2", class: "class2", data: %{}},
          %Paradigm.Graph.Node{id: "node3", class: "class1", data: %{}}
        ]

        graph = build_graph(nodes)

        classes = Paradigm.Graph.get_all_classes(graph)
        assert length(classes) == 2
        assert "class1" in classes
        assert "class2" in classes
      end

      test "get_all_nodes_of_class filters by class correctly" do
        nodes = [
          %Paradigm.Graph.Node{id: "node1", class: "class1", data: %{}},
          %Paradigm.Graph.Node{id: "node2", class: "class2", data: %{}},
          %Paradigm.Graph.Node{id: "node3", class: "class1", data: %{}}
        ]

        graph = build_graph(nodes)

        class1_nodes = Paradigm.Graph.get_all_nodes_of_class(graph, "class1")
        assert length(class1_nodes) == 2
        assert "node1" in class1_nodes
        assert "node3" in class1_nodes

        class2_nodes = Paradigm.Graph.get_all_nodes_of_class(graph, "class2")
        assert class2_nodes == ["node2"]

        # Test with multiple classes
        all_nodes = Paradigm.Graph.get_all_nodes_of_class(graph, ["class1", "class2"])
        assert length(all_nodes) == 3
      end

      test "stream_all_nodes returns enumerable of nodes" do
        nodes = [
          %Paradigm.Graph.Node{id: "node1", class: "class1", data: %{"prop" => "value1"}},
          %Paradigm.Graph.Node{id: "node2", class: "class2", data: %{"prop" => "value2"}}
        ]

        graph = build_graph(nodes)

        streamed_nodes = graph
                          |> Paradigm.Graph.stream_all_nodes()
                          |> Enum.to_list()

        assert length(streamed_nodes) == 2
        assert Enum.any?(streamed_nodes, &(&1.id == "node1"))
        assert Enum.any?(streamed_nodes, &(&1.id == "node2"))
      end

      test "get_node_data retrieves node data correctly" do
        node = %Paradigm.Graph.Node{
          id: "node1",
          class: "class1",
          data: %{"prop1" => "value1", "prop2" => "value2"}
        }

        graph = build_graph(node)

        assert Paradigm.Graph.get_node_data(graph, "node1", "prop1") == {:ok, "value1"}
        assert Paradigm.Graph.get_node_data(graph, "node1", "nonexistent") == :error
        assert Paradigm.Graph.get_node_data(graph, "nonexistent_node", "prop1") == :error
      end

      test "get_node_data with default returns correctly" do
        node = %Paradigm.Graph.Node{
          id: "node1",
          class: "class1",
          data: %{"prop1" => "value1"}
        }

        graph = build_graph(node)

        assert Paradigm.Graph.get_node_data(graph, "node1", "prop1", "default") == "value1"
        assert Paradigm.Graph.get_node_data(graph, "node1", "nonexistent", "default") == "default"
        assert Paradigm.Graph.get_node_data(graph, "nonexistent_node", "prop1", "default") == "default"
      end

      test "follow_reference works with node references" do
        target_node = %Paradigm.Graph.Node{id: "target", class: "class1", data: %{}}
        ref_node = %Paradigm.Graph.Node{
          id: "ref_node",
          class: "class2",
          data: %{"ref" => %Paradigm.Graph.Node.Ref{id: "target"}}
        }

        graph = build_graph([target_node, ref_node])

        referenced_node = Paradigm.Graph.follow_reference(graph, "ref_node", "ref")
        assert referenced_node == target_node

        # Test non-existent reference
        assert Paradigm.Graph.follow_reference(graph, "ref_node", "nonexistent") == nil

        # Test non-existent node
        assert Paradigm.Graph.follow_reference(graph, "nonexistent", "ref") == nil
      end
    end
  end
end
