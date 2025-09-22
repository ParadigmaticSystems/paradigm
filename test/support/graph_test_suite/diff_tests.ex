defmodule Paradigm.Graph.TestSuite.DiffTests do

  defmacro __using__(_opts) do
    quote do
      describe "diff/2" do
        test "returns empty Paradigm.Graph.Diff for identical Paradigm.Graphs" do
          graph1 = new_graph()
          |> Paradigm.Graph.insert_node(%Paradigm.Graph.Node{id: "node1", class: "class1", data: %{"key" => "value"}})
          |> Paradigm.Graph.insert_node(%Paradigm.Graph.Node{id: "node2", class: "class2", data: %{"key" => "value2"}})

          graph2 = new_graph()
          |> Paradigm.Graph.insert_node(%Paradigm.Graph.Node{id: "node1", class: "class1", data: %{"key" => "value"}})
          |> Paradigm.Graph.insert_node(%Paradigm.Graph.Node{id: "node2", class: "class2", data: %{"key" => "value2"}})

          result = Paradigm.Graph.Diff.diff(graph1, graph2)

          assert result.added == []
          assert result.removed == []
          assert result.changed == %{}
        end

        test "detects added nodes" do
          graph1 = new_graph()
          |> Paradigm.Graph.insert_node(%Paradigm.Graph.Node{id: "node1", class: "class1", data: %{"key" => "value"}})

          graph2 = new_graph()
          |> Paradigm.Graph.insert_node(%Paradigm.Graph.Node{id: "node1", class: "class1", data: %{"key" => "value"}})
          |> Paradigm.Graph.insert_node(%Paradigm.Graph.Node{id: "node2", class: "class2", data: %{"key" => "value2"}})

          result = Paradigm.Graph.Diff.diff(graph1, graph2)

          assert result.added == ["node2"]
          assert result.removed == []
          assert result.changed == %{}
        end

        test "detects removed nodes" do
          graph1 = new_graph()
          |> Paradigm.Graph.insert_node(%Paradigm.Graph.Node{id: "node1", class: "class1", data: %{"key" => "value"}})
          |> Paradigm.Graph.insert_node(%Paradigm.Graph.Node{id: "node2", class: "class2", data: %{"key" => "value2"}})

          graph2 = new_graph()
          |> Paradigm.Graph.insert_node(%Paradigm.Graph.Node{id: "node1", class: "class1", data: %{"key" => "value"}})

          result = Paradigm.Graph.Diff.diff(graph1, graph2)

          assert result.added == []
          assert result.removed == ["node2"]
          assert result.changed == %{}
        end

        test "detects class changes" do
          graph1 = new_graph()
          |> Paradigm.Graph.insert_node(%Paradigm.Graph.Node{id: "node1", class: "class1", data: %{"key" => "value"}})

          graph2 = new_graph()
          |> Paradigm.Graph.insert_node(%Paradigm.Graph.Node{id: "node1", class: "class2", data: %{"key" => "value"}})

          result = Paradigm.Graph.Diff.diff(graph1, graph2)

          assert result.added == []
          assert result.removed == []
          assert result.changed == %{
            "node1" => %{
              class: %{old: "class1", new: "class2"}
            }
          }
        end

        test "detects data changes" do
          graph1 = new_graph()
          |> Paradigm.Graph.insert_node(%Paradigm.Graph.Node{id: "node1", class: "class1", data: %{"key" => "old_value"}})

          graph2 = new_graph()
          |> Paradigm.Graph.insert_node(%Paradigm.Graph.Node{id: "node1", class: "class1", data: %{"key" => "new_value"}})

          result = Paradigm.Graph.Diff.diff(graph1, graph2)

          assert result.added == []
          assert result.removed == []
          assert result.changed == %{
            "node1" => %{
              data: %{
                "key" => %{old: "old_value", new: "new_value"}
              }
            }
          }
        end

        test "detects added data keys" do
          graph1 = new_graph()
          |> Paradigm.Graph.insert_node(%Paradigm.Graph.Node{id: "node1", class: "class1", data: %{"key1" => "value1"}})

          graph2 = new_graph()
          |> Paradigm.Graph.insert_node(%Paradigm.Graph.Node{id: "node1", class: "class1", data: %{"key1" => "value1", "key2" => "value2"}})

          result = Paradigm.Graph.Diff.diff(graph1, graph2)

          assert result.added == []
          assert result.removed == []
          assert result.changed == %{
            "node1" => %{
              data: %{
                "key2" => %{old: "MISSING VALUE", new: "value2"}
              }
            }
          }
        end

        test "detects removed data keys" do
          graph1 = new_graph()
          |> Paradigm.Graph.insert_node(%Paradigm.Graph.Node{id: "node1", class: "class1", data: %{"key1" => "value1", "key2" => "value2"}})

          graph2 = new_graph()
          |> Paradigm.Graph.insert_node(%Paradigm.Graph.Node{id: "node1", class: "class1", data: %{"key1" => "value1"}})

          result = Paradigm.Graph.Diff.diff(graph1, graph2)

          assert result.added == []
          assert result.removed == []
          assert result.changed == %{
            "node1" => %{
              data: %{
                "key2" => %{old: "value2", new: "MISSING VALUE"}
              }
            }
          }
        end

        test "detects both class and data changes" do
          graph1 = new_graph()
          |> Paradigm.Graph.insert_node(%Paradigm.Graph.Node{id: "node1", class: "class1", data: %{"key" => "old_value"}})

          graph2 = new_graph()
          |> Paradigm.Graph.insert_node(%Paradigm.Graph.Node{id: "node1", class: "class2", data: %{"key" => "new_value"}})

          result = Paradigm.Graph.Diff.diff(graph1, graph2)

          assert result.added == []
          assert result.removed == []
          assert result.changed == %{
            "node1" => %{
              class: %{old: "class1", new: "class2"},
              data: %{
                "key" => %{old: "old_value", new: "new_value"}
              }
            }
          }
        end

        test "handles empty Paradigm.Graphs" do
          graph1 = new_graph()
          graph2 = new_graph()

          result = Paradigm.Graph.Diff.diff(graph1, graph2)

          assert result.added == []
          assert result.removed == []
          assert result.changed == %{}
        end

        test "handles nodes with nil data" do
          graph1 = new_graph()
          |> Paradigm.Graph.insert_node(%Paradigm.Graph.Node{id: "node1", class: "class1", data: %{}})

          graph2 = new_graph()
          |> Paradigm.Graph.insert_node(%Paradigm.Graph.Node{id: "node1", class: "class1", data: %{"key" => "value"}})

          result = Paradigm.Graph.Diff.diff(graph1, graph2)

          assert result.added == []
          assert result.removed == []
          assert result.changed == %{
            "node1" => %{
              data: %{
                "key" => %{old: "MISSING VALUE", new: "value"}
              }
            }
          }
        end
      end
    end
  end
end
