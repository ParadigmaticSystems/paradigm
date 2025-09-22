defmodule Paradigm.Conformance.TestSuite.BasicValidation do
  defmacro __using__(_opts) do
    quote do
      alias Paradigm.Graph

      describe "check_graph/2" do
        test "validates valid graph" do
          paradigm = %Paradigm{
            primitive_types: %{"string" => %Paradigm.PrimitiveType{name: "String"}},
            classes: %{
              "class1" => %Paradigm.Class{
                name: "TestClass",
                owned_attributes: ["prop1"]
              }
            },
            properties: %{
              "prop1" => %Paradigm.Property{
                name: "testProp",
                lower_bound: 1,
                upper_bound: 1,
                type: "string"
              }
            }
          }

          node = %Paradigm.Graph.Node{id: "node1", class: "class1", data: %{"testProp" => "value"}}
          graph = build_graph(node)

          Paradigm.Conformance.assert_conforms(graph, paradigm)
        end

        test "detects invalid class" do
          paradigm = %Paradigm{
            classes: %{}
          }

          node = %Paradigm.Graph.Node{id: "node1", class: "invalid_class", data: %{}}
          graph = build_graph(node)

          assert %Paradigm.Conformance.Result{
                   issues: [
                     %Paradigm.Conformance.Issue{
                       property: nil,
                       kind: :invalid_class,
                       details: %{class: "invalid_class"},
                       node_id: "node1"
                     }
                   ]
                 } =
                   Paradigm.Conformance.check_graph(graph, paradigm)
        end

        test "validates inherited properties from superclass" do
          paradigm = %Paradigm{
            primitive_types: %{"string" => %Paradigm.PrimitiveType{name: "String"}},
            classes: %{
              "parent_class" => %Paradigm.Class{
                name: "ParentClass",
                owned_attributes: ["parent_prop"]
              },
              "child_class" => %Paradigm.Class{
                name: "ChildClass",
                owned_attributes: ["child_prop"],
                super_classes: ["parent_class"]
              }
            },
            properties: %{
              "parent_prop" => %Paradigm.Property{
                name: "parentProp",
                lower_bound: 1,
                upper_bound: 1,
                type: "string"
              },
              "child_prop" => %Paradigm.Property{
                name: "childProp",
                lower_bound: 1,
                upper_bound: 1,
                type: "string"
              }
            }
          }

          node = %Paradigm.Graph.Node{
            id: "node1",
            class: "child_class",
            data: %{
              "parentProp" => "parent_value",
              "childProp" => "child_value"
            }
          }
          graph = build_graph(node)

          Paradigm.Conformance.assert_conforms(graph, paradigm)

          # Missing inherited property
          invalid_node = %Paradigm.Graph.Node{
            id: "node1",
            class: "child_class",
            data: %{"childProp" => "child_value"}
          }
          invalid_graph = build_graph(invalid_node)

          assert %Paradigm.Conformance.Result{
                   issues: [
                     %Paradigm.Conformance.Issue{
                       property: "parentProp",
                       kind: :missing_property,
                       details: nil,
                       node_id: "node1"
                     }
                   ]
                 } =
                   Paradigm.Conformance.check_graph(invalid_graph, paradigm)
        end

        test "validates ordered property constraints" do
          paradigm = %Paradigm{
            primitive_types: %{"string" => %Paradigm.PrimitiveType{name: "String"}},
            classes: %{
              "class1" => %Paradigm.Class{
                name: "TestClass",
                owned_attributes: ["ordered_prop"]
              }
            },
            properties: %{
              "ordered_prop" => %Paradigm.Property{
                name: "orderedProp",
                is_ordered: true,
                lower_bound: 1,
                upper_bound: :infinity,
                type: "string"
              }
            }
          }

          node = %Paradigm.Graph.Node{
            id: "node1",
            class: "class1",
            data: %{"orderedProp" => ["value1", "value2", "value3"]}
          }
          graph = build_graph(node)

          Paradigm.Conformance.assert_conforms(graph, paradigm)
        end

        test "detects missing required properties" do
          paradigm = %Paradigm{
            primitive_types: %{"string" => %Paradigm.PrimitiveType{name: "String"}},
            classes: %{
              "class1" => %Paradigm.Class{
                name: "TestClass",
                owned_attributes: ["prop1"]
              }
            },
            properties: %{
              "prop1" => %Paradigm.Property{
                name: "testProp",
                type: "string"
              }
            }
          }

          node = %Paradigm.Graph.Node{id: "node1", class: "class1", data: %{}}
          graph = build_graph(node)

          assert %Paradigm.Conformance.Result{
                   issues: [
                     %Paradigm.Conformance.Issue{
                       property: "testProp",
                       kind: :missing_property,
                       details: nil,
                       node_id: "node1"
                     }
                   ]
                 } ==
                   Paradigm.Conformance.check_graph(graph, paradigm)
        end

        test "detects extra properties" do
          paradigm = %Paradigm{
            classes: %{
              "class1" => %Paradigm.Class{
                name: "TestClass",
                owned_attributes: []
              }
            }
          }

          node = %Paradigm.Graph.Node{
            id: "node1",
            class: "class1",
            data: %{"extraProp" => "value"}
          }
          graph = build_graph(node)

          assert %Paradigm.Conformance.Result{
                   issues: [
                     %Paradigm.Conformance.Issue{
                       property: "extraProp",
                       kind: :unknown_property,
                       details: nil,
                       node_id: "node1"
                     }
                   ]
                 } =
                   Paradigm.Conformance.check_graph(graph, paradigm)
        end

        test "validates enumeration values" do
          paradigm = %Paradigm{
            classes: %{
              "class1" => %Paradigm.Class{
                name: "TestClass",
                owned_attributes: ["enum_prop"]
              }
            },
            properties: %{
              "enum_prop" => %Paradigm.Property{
                name: "enumProp",
                type: "color_enum"
              }
            },
            enumerations: %{
              "color_enum" => %Paradigm.Enumeration{
                name: "Color",
                literals: ["RED", "GREEN", "BLUE"]
              }
            }
          }

          # Test valid enum value
          node1 = %Paradigm.Graph.Node{
            id: "node1",
            class: "class1",
            data: %{"enumProp" => "RED"}
          }
          graph1 = build_graph(node1)

          Paradigm.Conformance.assert_conforms(graph1, paradigm)

          # Test invalid enum value
          node2 = %Paradigm.Graph.Node{
            id: "node1",
            class: "class1",
            data: %{"enumProp" => "PURPLE"}
          }
          graph2 = build_graph(node2)

          assert %Paradigm.Conformance.Result{
                   issues: [
                     %Paradigm.Conformance.Issue{
                       property: "enumProp",
                       kind: :invalid_enum_value,
                       details: %{value: "PURPLE"},
                       node_id: "node1"
                     }
                   ]
                 } =
                   Paradigm.Conformance.check_graph(graph2, paradigm)
        end
      end

    end
  end
end
