defmodule Paradigm.Conformance.TestSuite.Multiplicity do
  defmacro __using__(_opts) do
    quote do
      test "validates property cardinality" do
        paradigm = %Paradigm{
          primitive_types: %{"string" => %Paradigm.PrimitiveType{name: "String"}},
          classes: %{
            "class1" => %Paradigm.Class{
              name: "TestClass",
              properties: %{
                "testProp" => %Paradigm.Property{
                  name: "testProp",
                  lower_bound: 2,
                  upper_bound: 3,
                  type: "string"
                }
              }
            }
          }
        }

        # Test too few values
        node1 = %Paradigm.Graph.Node{
          id: "node1",
          class: "class1",
          data: %{"testProp" => ["value1"]}
        }

        graph1 = build_graph(node1)

        assert %Paradigm.Conformance.Result{
                 issues: [
                   %Paradigm.Conformance.Issue{
                     property: "testProp",
                     kind: :cardinality_too_low,
                     details: %{count: 1, minimum: 2},
                     node_id: "node1"
                   }
                 ]
               } =
                 Paradigm.Conformance.check_graph(graph1, paradigm)

        # Test too many values
        node2 = %Paradigm.Graph.Node{
          id: "node1",
          class: "class1",
          data: %{"testProp" => ["value1", "value2", "value3", "value4"]}
        }

        graph2 = build_graph(node2)

        assert %Paradigm.Conformance.Result{
                 issues: [
                   %Paradigm.Conformance.Issue{
                     property: "testProp",
                     kind: :cardinality_too_high,
                     details: %{count: 4, maximum: 3},
                     node_id: "node1"
                   }
                 ]
               } =
                 Paradigm.Conformance.check_graph(graph2, paradigm)
      end

      test "validates property cardinality edge cases" do
        paradigm = %Paradigm{
          primitive_types: %{"string" => %Paradigm.PrimitiveType{name: "String"}},
          classes: %{
            "class1" => %Paradigm.Class{
              name: "TestClass",
              properties: %{
                "zeroProp" => %Paradigm.Property{
                  name: "zeroProp",
                  lower_bound: 0,
                  upper_bound: 0,
                  type: "string"
                },
                "optionalProp" => %Paradigm.Property{
                  name: "optionalProp",
                  lower_bound: 0,
                  upper_bound: 1,
                  type: "string"
                },
                "infiniteProp" => %Paradigm.Property{
                  name: "infiniteProp",
                  lower_bound: 1,
                  upper_bound: :infinity,
                  type: "string"
                }
              }
            }
          }
        }

        # Test zero cardinality
        node1 = %Paradigm.Graph.Node{
          id: "node1",
          class: "class1",
          data: %{
            "zeroProp" => [],
            "optionalProp" => [],
            "infiniteProp" => ["value1"]
          }
        }

        graph1 = build_graph(node1)

        Paradigm.Conformance.assert_conforms(graph1, paradigm)

        # Test optional property
        node2 = %Paradigm.Graph.Node{
          id: "node1",
          class: "class1",
          data: %{
            "zeroProp" => [],
            "optionalProp" => ["value"],
            "infiniteProp" => ["value1"]
          }
        }

        graph2 = build_graph(node2)

        Paradigm.Conformance.assert_conforms(graph2, paradigm)

        # Test infinite upper bound
        node3 = %Paradigm.Graph.Node{
          id: "node1",
          class: "class1",
          data: %{
            "zeroProp" => [],
            "optionalProp" => [],
            "infiniteProp" => List.duplicate("value", 100)
          }
        }

        graph3 = build_graph(node3)

        Paradigm.Conformance.assert_conforms(graph3, paradigm)
      end
    end
  end
end
