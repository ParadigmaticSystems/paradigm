defmodule Paradigm.Graph.DiffTest do
  use ExUnit.Case
  alias Paradigm.Graph.{Diff, MapGraph, Node}
  alias Paradigm.Graph

  describe "assert_equal/2" do
    test "returns :ok for identical graphs" do
      graph1 =
        MapGraph.new()
        |> Graph.insert_node(%Node{id: "node1", class: "class1", data: %{"key" => "value"}})

      graph2 =
        MapGraph.new()
        |> Graph.insert_node(%Node{id: "node1", class: "class1", data: %{"key" => "value"}})

      assert Diff.assert_equal(graph1, graph2) == :ok
    end

    test "raises error for different graphs with added nodes" do
      graph1 =
        MapGraph.new()
        |> Graph.insert_node(%Node{id: "node1", class: "class1", data: %{"key" => "value"}})

      graph2 =
        MapGraph.new()
        |> Graph.insert_node(%Node{id: "node1", class: "class1", data: %{"key" => "value"}})
        |> Graph.insert_node(%Node{id: "node2", class: "class2", data: %{"key" => "value2"}})

      assert_raise RuntimeError, ~r/Graphs are not equal/, fn ->
        Diff.assert_equal(graph1, graph2)
      end
    end

    test "raises error for different graphs with removed nodes" do
      graph1 =
        MapGraph.new()
        |> Graph.insert_node(%Node{id: "node1", class: "class1", data: %{"key" => "value"}})
        |> Graph.insert_node(%Node{id: "node2", class: "class2", data: %{"key" => "value2"}})

      graph2 =
        MapGraph.new()
        |> Graph.insert_node(%Node{id: "node1", class: "class1", data: %{"key" => "value"}})

      assert_raise RuntimeError, ~r/Graphs are not equal/, fn ->
        Diff.assert_equal(graph1, graph2)
      end
    end

    test "raises error for different graphs with changed nodes" do
      graph1 =
        MapGraph.new()
        |> Graph.insert_node(%Node{id: "node1", class: "class1", data: %{"key" => "old_value"}})

      graph2 =
        MapGraph.new()
        |> Graph.insert_node(%Node{id: "node1", class: "class1", data: %{"key" => "new_value"}})

      assert_raise RuntimeError, ~r/Graphs are not equal/, fn ->
        Diff.assert_equal(graph1, graph2)
      end
    end

    test "raises error for different graphs with changed node ownership" do
      graph1 =
        MapGraph.new()
        |> Graph.insert_node(%Node{
          id: "node1",
          class: "class1",
          owned_by: "owner1",
          data: %{"key" => "value"}
        })

      graph2 =
        MapGraph.new()
        |> Graph.insert_node(%Node{
          id: "node1",
          class: "class1",
          owned_by: "owner2",
          data: %{"key" => "value"}
        })

      assert_raise RuntimeError, ~r/Graphs are not equal/, fn ->
        Diff.assert_equal(graph1, graph2)
      end
    end

    test "error message includes detailed differences" do
      graph1 =
        MapGraph.new()
        |> Graph.insert_node(%Node{id: "node1", class: "class1", data: %{"key" => "old_value"}})

      graph2 =
        MapGraph.new()
        |> Graph.insert_node(%Node{id: "node1", class: "class2", data: %{"key" => "new_value"}})
        |> Graph.insert_node(%Node{id: "node2", class: "class3", data: %{"key" => "value"}})

      try do
        Diff.assert_equal(graph1, graph2)
      rescue
        error ->
          message = Exception.message(error)
          assert message =~ "Added nodes:"
          assert message =~ "node2"
          assert message =~ "Changed nodes:"
          assert message =~ "node1"
          assert message =~ "class1"
          assert message =~ "class2"
          assert message =~ "old_value"
          assert message =~ "new_value"
      end
    end

    test "diff works across graph implementations" do
      map_graph =
        MapGraph.new()
        |> Graph.insert_node(%Node{
          id: "/.",
          class: "folder",
          owned_by: "/.",
          data: %{
            "children" => [
              %Paradigm.Graph.Node.Ref{id: "/file1.txt", composite: true},
              %Paradigm.Graph.Node.Ref{id: "/subfolder", composite: true}
            ],
            "name" => ".",
            "parent" => %Paradigm.Graph.Node.Ref{id: "/.", composite: true}
          }
        })
        |> Graph.insert_node(%Node{
          id: "/file1.txt",
          class: "file",
          owned_by: "/.",
          data: %{
            "contents" => "file 1 contents\n",
            "extension" => ".txt",
            "name" => "file1.txt",
            "parent" => %Paradigm.Graph.Node.Ref{id: "/.", composite: false}
          }
        })
        |> Graph.insert_node(%Node{
          id: "/subfolder",
          class: "folder",
          owned_by: "/.",
          data: %{
            "children" => [
              %Paradigm.Graph.Node.Ref{id: "/subfolder/file2.txt", composite: true}
            ],
            "name" => "subfolder",
            "parent" => %Paradigm.Graph.Node.Ref{id: "/.", composite: true}
          }
        })
        |> Graph.insert_node(%Node{
          id: "/subfolder/file2.txt",
          class: "file",
          owned_by: "/subfolder",
          data: %{
            "contents" => "file 2 contents\n",
            "extension" => ".txt",
            "name" => "file2.txt",
            "parent" => %Paradigm.Graph.Node.Ref{id: "/subfolder", composite: false}
          }
        })

      fs_graph = Paradigm.Graph.FilesystemGraph.new(root: "./test/graph/data/fs_graph")

      Diff.assert_equal(map_graph, fs_graph)
    end
  end
end
