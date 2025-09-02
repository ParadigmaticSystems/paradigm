defmodule Paradigm.ConformanceTest do
  use ExUnit.Case
  alias Paradigm.Conformance
  alias Paradigm.Graph.MapGraph
  alias Paradigm.Graph.Node
  alias Paradigm.Graph.Node.Ref

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

      node = %Node{id: "node1", class: "class1", data: %{"testProp" => "value"}}
      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node(node)

      Paradigm.Conformance.assert_conforms(graph, paradigm)
    end

    test "detects invalid class reference" do
      paradigm = %Paradigm{
        classes: %{}
      }

      node = %Node{id: "node1", class: "invalid_class", data: %{}}
      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node(node)

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
               Conformance.check_graph(graph, paradigm)
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

      node = %Node{
        id: "node1",
        class: "child_class",
        data: %{
          "parentProp" => "parent_value",
          "childProp" => "child_value"
        }
      }
      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node(node)

      Paradigm.Conformance.assert_conforms(graph, paradigm)

      # Missing inherited property
      invalid_node = %Node{
        id: "node1",
        class: "child_class",
        data: %{"childProp" => "child_value"}
      }
      invalid_graph = MapGraph.new()
                      |> Paradigm.Graph.insert_node(invalid_node)

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
               Conformance.check_graph(invalid_graph, paradigm)
    end

    test "validates property references to superclass type" do
      paradigm = %Paradigm{
        classes: %{
          "cow" => %Paradigm.Class{
            name: "Cow",
            owned_attributes: []
          },
          "vehicle" => %Paradigm.Class{
            name: "Vehicle",
            owned_attributes: []
          },
          "truck" => %Paradigm.Class{
            name: "Truck",
            super_classes: ["vehicle"],
            owned_attributes: []
          },
          "garage" => %Paradigm.Class{
            name: "Garage",
            owned_attributes: ["vehicle_ref"]
          }
        },
        properties: %{
          "vehicle_ref" => %Paradigm.Property{
            name: "vehicleRef",
            lower_bound: 1,
            upper_bound: 1,
            type: "vehicle"
          }
        }
      }

      node1 = %Node{id: "node1", class: "cow", data: %{}}
      node2 = %Node{
        id: "node2",
        class: "garage",
        data: %{"vehicleRef" => %Ref{id: "node1"}}
      }
      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node(node1)
              |> Paradigm.Graph.insert_node(node2)

      assert %Paradigm.Conformance.Result{
               issues: [
                 %Paradigm.Conformance.Issue{
                   property: "vehicleRef",
                   kind: :references_wrong_class,
                   details: %{class: "cow"},
                   node_id: "node2"
                 }
               ]
             } = Conformance.check_graph(graph, paradigm)
    end

    test "validates valid reference to correct class" do
      paradigm = %Paradigm{
        classes: %{
          "vehicle" => %Paradigm.Class{
            name: "Vehicle",
            owned_attributes: []
          },
          "truck" => %Paradigm.Class{
            name: "Truck",
            super_classes: ["vehicle"],
            owned_attributes: []
          },
          "garage" => %Paradigm.Class{
            name: "Garage",
            owned_attributes: ["vehicle_ref"]
          }
        },
        properties: %{
          "vehicle_ref" => %Paradigm.Property{
            name: "vehicleRef",
            lower_bound: 1,
            upper_bound: 1,
            type: "vehicle"
          }
        }
      }

      # Test direct class match
      node1 = %Node{id: "node1", class: "vehicle", data: %{}}
      node2 = %Node{
        id: "node2",
        class: "garage",
        data: %{"vehicleRef" => %Ref{id: "node1"}}
      }
      graph1 = MapGraph.new()
               |> Paradigm.Graph.insert_node(node1)
               |> Paradigm.Graph.insert_node(node2)

      Paradigm.Conformance.assert_conforms(graph1, paradigm)

      # Test subclass match
      truck_node = %Node{id: "node1", class: "truck", data: %{}}
      garage_node = %Node{
        id: "node2",
        class: "garage",
        data: %{"vehicleRef" => %Ref{id: "node1"}}
      }
      graph2 = MapGraph.new()
               |> Paradigm.Graph.insert_node(truck_node)
               |> Paradigm.Graph.insert_node(garage_node)

      Paradigm.Conformance.assert_conforms(graph2, paradigm)
    end

    test "detects reference to nonexistent node" do
      paradigm = %Paradigm{
        classes: %{
          "vehicle" => %Paradigm.Class{
            name: "Vehicle",
            owned_attributes: []
          },
          "garage" => %Paradigm.Class{
            name: "Garage",
            owned_attributes: ["vehicle_ref"]
          }
        },
        properties: %{
          "vehicle_ref" => %Paradigm.Property{
            name: "vehicleRef",
            lower_bound: 1,
            upper_bound: 1,
            type: "vehicle"
          }
        }
      }

      node = %Node{
        id: "node1",
        class: "garage",
        data: %{"vehicleRef" => %Ref{id: "nonexistent_node"}}
      }
      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node(node)

      assert %Paradigm.Conformance.Result{
               issues: [
                 %Paradigm.Conformance.Issue{
                   property: "vehicleRef",
                   kind: :references_missing_node,
                   details: %{referenced_id: "nonexistent_node"},
                   node_id: "node1"
                 }
               ]
             } = Conformance.check_graph(graph, paradigm)
    end

    test "validates multiple references in collection" do
      paradigm = %Paradigm{
        classes: %{
          "vehicle" => %Paradigm.Class{
            name: "Vehicle",
            owned_attributes: []
          },
          "garage" => %Paradigm.Class{
            name: "Garage",
            owned_attributes: ["vehicle_refs"]
          }
        },
        properties: %{
          "vehicle_refs" => %Paradigm.Property{
            name: "vehicleRefs",
            lower_bound: 0,
            upper_bound: :infinity,
            type: "vehicle"
          }
        }
      }

      node1 = %Node{id: "node1", class: "vehicle", data: %{}}
      node2 = %Node{id: "node2", class: "vehicle", data: %{}}
      node3 = %Node{
        id: "node3",
        class: "garage",
        data: %{"vehicleRefs" => [%Ref{id: "node1"}, %Ref{id: "node2"}]}
      }
      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node(node1)
              |> Paradigm.Graph.insert_node(node2)
              |> Paradigm.Graph.insert_node(node3)

      Paradigm.Conformance.assert_conforms(graph, paradigm)
    end

    test "validates mixed references and dangling references in collection" do
      paradigm = %Paradigm{
        classes: %{
          "vehicle" => %Paradigm.Class{
            name: "Vehicle",
            owned_attributes: []
          },
          "garage" => %Paradigm.Class{
            name: "Garage",
            owned_attributes: ["vehicle_refs"]
          }
        },
        properties: %{
          "vehicle_refs" => %Paradigm.Property{
            name: "vehicleRefs",
            lower_bound: 0,
            upper_bound: :infinity,
            type: "vehicle"
          }
        }
      }

      node1 = %Node{id: "node1", class: "vehicle", data: %{}}
      node2 = %Node{
        id: "node2",
        class: "garage",
        data: %{"vehicleRefs" => [%Ref{id: "node1"}, %Ref{id: "missing_node"}]}
      }
      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node(node1)
              |> Paradigm.Graph.insert_node(node2)

      assert %Paradigm.Conformance.Result{
               issues: [
                 %Paradigm.Conformance.Issue{
                   property: "vehicleRefs",
                   kind: :references_missing_node,
                   details: %{referenced_id: "missing_node"},
                   node_id: "node2"
                 }
               ]
             } = Conformance.check_graph(graph, paradigm)
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

      node = %Node{
        id: "node1",
        class: "class1",
        data: %{"orderedProp" => ["value1", "value2", "value3"]}
      }
      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node(node)

      Paradigm.Conformance.assert_conforms(graph, paradigm)
    end

    test "validates property cardinality edge cases" do
      paradigm = %Paradigm{
        primitive_types: %{"string" => %Paradigm.PrimitiveType{name: "String"}},
        classes: %{
          "class1" => %Paradigm.Class{
            name: "TestClass",
            owned_attributes: ["prop1", "prop2", "prop3"]
          }
        },
        properties: %{
          "prop1" => %Paradigm.Property{
            name: "zeroProp",
            lower_bound: 0,
            upper_bound: 0,
            type: "string"
          },
          "prop2" => %Paradigm.Property{
            name: "optionalProp",
            lower_bound: 0,
            upper_bound: 1,
            type: "string"
          },
          "prop3" => %Paradigm.Property{
            name: "infiniteProp",
            lower_bound: 1,
            upper_bound: :infinity,
            type: "string"
          }
        }
      }

      # Test zero cardinality
      node1 = %Node{
        id: "node1",
        class: "class1",
        data: %{
          "zeroProp" => [],
          "optionalProp" => [],
          "infiniteProp" => ["value1"]
        }
      }
      graph1 = MapGraph.new()
               |> Paradigm.Graph.insert_node(node1)

      Paradigm.Conformance.assert_conforms(graph1, paradigm)

      # Test optional property
      node2 = %Node{
        id: "node1",
        class: "class1",
        data: %{
          "zeroProp" => [],
          "optionalProp" => ["value"],
          "infiniteProp" => ["value1"]
        }
      }
      graph2 = MapGraph.new()
               |> Paradigm.Graph.insert_node(node2)

      Paradigm.Conformance.assert_conforms(graph2, paradigm)

      # Test infinite upper bound
      node3 = %Node{
        id: "node1",
        class: "class1",
        data: %{
          "zeroProp" => [],
          "optionalProp" => [],
          "infiniteProp" => List.duplicate("value", 100)
        }
      }
      graph3 = MapGraph.new()
               |> Paradigm.Graph.insert_node(node3)

      Paradigm.Conformance.assert_conforms(graph3, paradigm)
    end

    test "detects non-reference value for reference property" do
      paradigm = %Paradigm{
        classes: %{
          "vehicle" => %Paradigm.Class{
            name: "Vehicle",
            owned_attributes: []
          },
          "garage" => %Paradigm.Class{
            name: "Garage",
            owned_attributes: ["vehicle_ref"]
          }
        },
        properties: %{
          "vehicle_ref" => %Paradigm.Property{
            name: "vehicleRef",
            lower_bound: 1,
            upper_bound: 1,
            type: "vehicle"
          }
        }
      }

      # Property should contain %Ref{} but has string instead
      node = %Node{
        id: "node1",
        class: "garage",
        data: %{"vehicleRef" => "not_a_reference"}  # Should be %Ref{id: "..."}
      }
      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node(node)

      assert %Paradigm.Conformance.Result{
        issues: [
          %Paradigm.Conformance.Issue{
            property: "vehicleRef",
            kind: :expected_reference,
            details: %{actual_type: "string"},
            node_id: "node1"
          }
        ]
      } = Conformance.check_graph(graph, paradigm)
    end

    test "validates composite property constraints" do
      paradigm = %Paradigm{
        classes: %{
          "container" => %Paradigm.Class{
            name: "Container",
            owned_attributes: ["composite_parts"]
          },
          "part" => %Paradigm.Class{
            name: "Part",
            owned_attributes: []
          }
        },
        properties: %{
          "composite_parts" => %Paradigm.Property{
            name: "compositeParts",
            is_composite: true,
            lower_bound: 1,
            upper_bound: :infinity,
            type: "part"
          }
        }
      }

      part1 = %Node{id: "part1", class: "part", data: %{}}
      part2 = %Node{id: "part2", class: "part", data: %{}}
      container = %Node{
        id: "container1",
        class: "container",
        data: %{"compositeParts" => [%Ref{id: "part1", composite: true}, %Ref{id: "part2", composite: true}]}
      }
      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node(part1)
              |> Paradigm.Graph.insert_node(part2)
              |> Paradigm.Graph.insert_node(container)

      Paradigm.Conformance.assert_conforms(graph, paradigm)
    end

    test "detects composite property with primitive type" do
      paradigm = %Paradigm{
        primitive_types: %{"string" => %Paradigm.PrimitiveType{name: "String"}},
        classes: %{
          "class1" => %Paradigm.Class{
            name: "TestClass",
            owned_attributes: ["invalid_composite"]
          }
        },
        properties: %{
          "invalid_composite" => %Paradigm.Property{
            name: "invalidComposite",
            is_composite: true,
            type: "string",
            upper_bound: 2
          }
        }
      }

      node = %Node{
        id: "node1",
        class: "class1",
        data: %{"invalidComposite" => ["value1", "value2"]}
      }
      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node(node)

      assert %Paradigm.Conformance.Result{
               issues: [
                 %Paradigm.Conformance.Issue{
                   property: "invalidComposite",
                   kind: :composite_primitive_type,
                   details: %{type: "string"},
                   node_id: "node1"
                 }
               ]
             } = Conformance.check_graph(graph, paradigm)
    end

    test "validates composite ownership exclusivity" do
      paradigm = %Paradigm{
        classes: %{
          "container1" => %Paradigm.Class{
            name: "Container1",
            owned_attributes: ["parts"]
          },
          "container2" => %Paradigm.Class{
            name: "Container2",
            owned_attributes: ["parts"]
          },
          "part" => %Paradigm.Class{
            name: "Part",
            owned_attributes: []
          }
        },
        properties: %{
          "parts" => %Paradigm.Property{
            name: "parts",
            is_composite: true,
            lower_bound: 0,
            upper_bound: :infinity,
            type: "part"
          }
        }
      }

      # Same part referenced by two composite properties (should fail)
      part1 = %Node{id: "part1", class: "part", data: %{}}
      container1 = %Node{
        id: "container1",
        class: "container1",
        data: %{"parts" => [%Ref{id: "part1", composite: true}]}
      }
      container2 = %Node{
        id: "container2",
        class: "container2",
        data: %{"parts" => [%Ref{id: "part1", composite: true}]}
      }
      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node(part1)
              |> Paradigm.Graph.insert_node(container1)
              |> Paradigm.Graph.insert_node(container2)

      assert %Paradigm.Conformance.Result{
               issues: [
                 %Paradigm.Conformance.Issue{
                   property: "parts",
                   kind: :multiple_composite_owners,
                   node_id: "container1"
                 }
               ]
             } = Conformance.check_graph(graph, paradigm)
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

      node = %Node{id: "node1", class: "class1", data: %{}}
      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node(node)

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
               Conformance.check_graph(graph, paradigm)
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

      node = %Node{
        id: "node1",
        class: "class1",
        data: %{"extraProp" => "value"}
      }
      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node(node)

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
               Conformance.check_graph(graph, paradigm)
    end

    test "validates property cardinality" do
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
            lower_bound: 2,
            upper_bound: 3,
            type: "string"
          }
        }
      }

      # Test too few values
      node1 = %Node{
        id: "node1",
        class: "class1",
        data: %{"testProp" => ["value1"]}
      }
      graph1 = MapGraph.new()
               |> Paradigm.Graph.insert_node(node1)

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
               Conformance.check_graph(graph1, paradigm)

      # Test too many values
      node2 = %Node{
        id: "node1",
        class: "class1",
        data: %{"testProp" => ["value1", "value2", "value3", "value4"]}
      }
      graph2 = MapGraph.new()
               |> Paradigm.Graph.insert_node(node2)

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
               Conformance.check_graph(graph2, paradigm)
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
      node1 = %Node{
        id: "node1",
        class: "class1",
        data: %{"enumProp" => "RED"}
      }
      graph1 = MapGraph.new()
               |> Paradigm.Graph.insert_node(node1)

      Paradigm.Conformance.assert_conforms(graph1, paradigm)

      # Test invalid enum value
      node2 = %Node{
        id: "node1",
        class: "class1",
        data: %{"enumProp" => "PURPLE"}
      }
      graph2 = MapGraph.new()
               |> Paradigm.Graph.insert_node(node2)

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
               Conformance.check_graph(graph2, paradigm)
    end
  end
end
