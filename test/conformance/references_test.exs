defmodule Paradigm.Conformance.ReferenceTest do
  use Paradigm.TestHelper

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

end
