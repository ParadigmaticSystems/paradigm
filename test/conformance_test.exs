defmodule Paradigm.ConformanceTest do
  use ExUnit.Case
  alias Paradigm.Conformance
  alias Paradigm.Graph.{Instance, MapImpl}

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

      graph = %{
        "node1" => %{
          class: "class1",
          data: %{
            "testProp" => "value"
          }
        }
      }

      instance = %Instance{impl: MapImpl, data: graph}

      assert %Paradigm.Conformance.Result{issues: []} =
               Conformance.check_graph(paradigm, instance)
    end

    test "detects invalid class reference" do
      paradigm = %Paradigm{
        classes: %{}
      }

      graph = %{
        "node1" => %{
          class: "invalid_class",
          data: %{}
        }
      }

      instance = %Instance{impl: MapImpl, data: graph}

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
               Conformance.check_graph(paradigm, instance)
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

      graph = %{
        "node1" => %{
          class: "child_class",
          data: %{
            "parentProp" => "parent_value",
            "childProp" => "child_value"
          }
        }
      }

      instance = %Instance{impl: MapImpl, data: graph}

      assert %Paradigm.Conformance.Result{issues: []} =
               Conformance.check_graph(paradigm, instance)

      # Missing inherited property
      invalid_graph = %{
        "node1" => %{
          class: "child_class",
          data: %{
            "childProp" => "child_value"
          }
        }
      }

      invalid_instance = %Instance{impl: MapImpl, data: invalid_graph}

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
               Conformance.check_graph(paradigm, invalid_instance)
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

      graph = %{
        "node1" => %{
          class: "cow",
          data: %{}
        },
        "node2" => %{
          class: "garage",
          data: %{
            "vehicleRef" => "node1"
          }
        }
      }

      instance = %Instance{impl: MapImpl, data: graph}

      assert %Paradigm.Conformance.Result{
               issues: [
                 %Paradigm.Conformance.Issue{
                   property: "vehicleRef",
                   kind: :references_wrong_class,
                   details: %{class: "cow"},
                   node_id: "node2"
                 }
               ]
             } = Conformance.check_graph(paradigm, instance)
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

      graph = %{
        "node1" => %{
          class: "class1",
          data: %{
            "orderedProp" => ["value1", "value2", "value3"]
          }
        }
      }

      instance = %Instance{impl: MapImpl, data: graph}

      assert %Paradigm.Conformance.Result{issues: []} =
               Conformance.check_graph(paradigm, instance)
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
      graph1 = %{
        "node1" => %{
          class: "class1",
          data: %{
            "zeroProp" => [],
            "optionalProp" => [],
            "infiniteProp" => ["value1"]
          }
        }
      }

      instance1 = %Instance{impl: MapImpl, data: graph1}

      assert %Paradigm.Conformance.Result{issues: []} =
               Conformance.check_graph(paradigm, instance1)

      # Test optional property
      graph2 = %{
        "node1" => %{
          class: "class1",
          data: %{
            "zeroProp" => [],
            "optionalProp" => ["value"],
            "infiniteProp" => ["value1"]
          }
        }
      }

      instance2 = %Instance{impl: MapImpl, data: graph2}

      assert %Paradigm.Conformance.Result{issues: []} =
               Conformance.check_graph(paradigm, instance2)

      # Test infinite upper bound
      graph3 = %{
        "node1" => %{
          class: "class1",
          data: %{
            "zeroProp" => [],
            "optionalProp" => [],
            "infiniteProp" => List.duplicate("value", 100)
          }
        }
      }

      instance3 = %Instance{impl: MapImpl, data: graph3}

      assert %Paradigm.Conformance.Result{issues: []} =
               Conformance.check_graph(paradigm, instance3)
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

      graph = %{
        "node1" => %{
          class: "class1",
          data: %{
            "compositeProp" => ["ref1", "ref2"]
          }
        }
      }

      instance = %Instance{impl: MapImpl, data: graph}

      assert %Paradigm.Conformance.Result{issues: []} =
               Conformance.check_graph(paradigm, instance)
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

      graph = %{
        "node1" => %{
          class: "class1",
          data: %{}
        }
      }

      instance = %Instance{impl: MapImpl, data: graph}

      assert %Paradigm.Conformance.Result{
               issues: [
                 %Paradigm.Conformance.Issue{
                   property: "testProp",
                   kind: :missing_property,
                   details: nil,
                   node_id: "node1"
                 }
               ]
             } =
               Conformance.check_graph(paradigm, instance)
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

      graph = %{
        "node1" => %{
          class: "class1",
          data: %{
            "extraProp" => "value"
          }
        }
      }

      instance = %Instance{impl: MapImpl, data: graph}

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
               Conformance.check_graph(paradigm, instance)
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
      graph1 = %{
        "node1" => %{
          class: "class1",
          data: %{
            "testProp" => ["value1"]
          }
        }
      }

      instance1 = %Instance{impl: MapImpl, data: graph1}

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
               Conformance.check_graph(paradigm, instance1)

      # Test too many values
      graph2 = %{
        "node1" => %{
          class: "class1",
          data: %{
            "testProp" => ["value1", "value2", "value3", "value4"]
          }
        }
      }

      instance2 = %Instance{impl: MapImpl, data: graph2}

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
               Conformance.check_graph(paradigm, instance2)
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
      graph1 = %{
        "node1" => %{
          class: "class1",
          data: %{
            "enumProp" => "RED"
          }
        }
      }

      instance1 = %Instance{impl: MapImpl, data: graph1}

      assert %Paradigm.Conformance.Result{issues: []} =
               Conformance.check_graph(paradigm, instance1)

      # Test invalid enum value
      graph2 = %{
        "node1" => %{
          class: "class1",
          data: %{
            "enumProp" => "PURPLE"
          }
        }
      }

      instance2 = %Instance{impl: MapImpl, data: graph2}

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
               Conformance.check_graph(paradigm, instance2)
    end
  end
end
