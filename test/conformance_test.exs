defmodule Paradigm.ConformanceTest do
  use ExUnit.Case
  alias Paradigm.Conformance
  alias Paradigm.Graph.MapGraph
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

      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node("node1", "class1", %{
                "testProp" => "value"
              })

      assert Paradigm.Conformance.conforms?(graph, paradigm)
    end

    test "detects invalid class reference" do
      paradigm = %Paradigm{
        classes: %{}
      }

      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node("node1", "invalid_class", %{})

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

      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node("node1", "child_class", %{
                "parentProp" => "parent_value",
                "childProp" => "child_value"
              })

      assert Paradigm.Conformance.conforms?(graph, paradigm)

      # Missing inherited property
      invalid_graph = MapGraph.new()
                      |> Paradigm.Graph.insert_node("node1", "child_class", %{
                        "childProp" => "child_value"
                      })

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

      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node("node1", "cow", %{})
              |> Paradigm.Graph.insert_node("node2", "garage", %{
                "vehicleRef" => %Ref{id: "node1"}
              })

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
      graph1 = MapGraph.new()
               |> Paradigm.Graph.insert_node("node1", "vehicle", %{})
               |> Paradigm.Graph.insert_node("node2", "garage", %{
                 "vehicleRef" => %Ref{id: "node1"}
               })

      assert Paradigm.Conformance.conforms?(graph1, paradigm)

      # Test subclass match
      graph2 = MapGraph.new()
               |> Paradigm.Graph.insert_node("node1", "truck", %{})
               |> Paradigm.Graph.insert_node("node2", "garage", %{
                 "vehicleRef" => %Ref{id: "node1"}
               })

      assert Paradigm.Conformance.conforms?(graph2, paradigm)
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

      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node("node1", "garage", %{
                "vehicleRef" => %Ref{id: "nonexistent_node"}
              })

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

      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node("node1", "vehicle", %{})
              |> Paradigm.Graph.insert_node("node2", "vehicle", %{})
              |> Paradigm.Graph.insert_node("node3", "garage", %{
                "vehicleRefs" => [%Ref{id: "node1"}, %Ref{id: "node2"}]
              })

      assert Paradigm.Conformance.conforms?(graph, paradigm)
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

      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node("node1", "vehicle", %{})
              |> Paradigm.Graph.insert_node("node2", "garage", %{
                "vehicleRefs" => [%Ref{id: "node1"}, %Ref{id: "missing_node"}]
              })

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

      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node("node1", "class1", %{
                "orderedProp" => ["value1", "value2", "value3"]
              })

      assert Paradigm.Conformance.conforms?(graph, paradigm)
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
      graph1 = MapGraph.new()
               |> Paradigm.Graph.insert_node("node1", "class1", %{
                 "zeroProp" => [],
                 "optionalProp" => [],
                 "infiniteProp" => ["value1"]
               })

      assert Paradigm.Conformance.conforms?(graph1, paradigm)

      # Test optional property
      graph2 = MapGraph.new()
               |> Paradigm.Graph.insert_node("node1", "class1", %{
                 "zeroProp" => [],
                 "optionalProp" => ["value"],
                 "infiniteProp" => ["value1"]
               })

      assert Paradigm.Conformance.conforms?(graph2, paradigm)

      # Test infinite upper bound
      graph3 = MapGraph.new()
               |> Paradigm.Graph.insert_node("node1", "class1", %{
                 "zeroProp" => [],
                 "optionalProp" => [],
                 "infiniteProp" => List.duplicate("value", 100)
               })

      assert Paradigm.Conformance.conforms?(graph3, paradigm)
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
      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node("node1", "garage", %{
                "vehicleRef" => "not_a_reference"  # Should be %Ref{id: "..."}
              })

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
        primitive_types: %{"string" => %Paradigm.PrimitiveType{name: "String"}},
        classes: %{
          "class1" => %Paradigm.Class{
            name: "TestClass",
            owned_attributes: ["composite_prop"]
          }
        },
        properties: %{
          "composite_prop" => %Paradigm.Property{
            name: "compositeProp",
            is_composite: true,
            lower_bound: 1,
            upper_bound: :infinity,
            type: "string"
          }
        }
      }

      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node("node1", "class1", %{
                "compositeProp" => [%Ref{id: "ref1"}, %Ref{id: "ref2"}]
              })

      assert Paradigm.Conformance.conforms?(graph, paradigm)
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

      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node("node1", "class1", %{})

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

      graph = MapGraph.new()
              |> Paradigm.Graph.insert_node("node1", "class1", %{
                "extraProp" => "value"
              })

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
      graph1 = MapGraph.new()
               |> Paradigm.Graph.insert_node("node1", "class1", %{
                 "testProp" => ["value1"]
               })

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
      graph2 = MapGraph.new()
               |> Paradigm.Graph.insert_node("node1", "class1", %{
                 "testProp" => ["value1", "value2", "value3", "value4"]
               })

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
      graph1 = MapGraph.new()
               |> Paradigm.Graph.insert_node("node1", "class1", %{
                 "enumProp" => "RED"
               })

      assert Paradigm.Conformance.conforms?(graph1, paradigm)

      # Test invalid enum value
      graph2 = MapGraph.new()
               |> Paradigm.Graph.insert_node("node1", "class1", %{
                 "enumProp" => "PURPLE"
               })

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
