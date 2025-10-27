defmodule Paradigm.Conformance.TestSuite.References do
  defmacro __using__(_opts) do
    quote do
      test "validates property references to superclass type" do
        paradigm = %Paradigm{
          classes: %{
            "cow" => %Paradigm.Class{
              name: "Cow",
              properties: %{}
            },
            "vehicle" => %Paradigm.Class{
              name: "Vehicle",
              properties: %{}
            },
            "truck" => %Paradigm.Class{
              name: "Truck",
              super_classes: ["vehicle"],
              properties: %{}
            },
            "garage" => %Paradigm.Class{
              name: "Garage",
              properties: %{
                "vehicleRef" => %Paradigm.Property{
                  name: "vehicleRef",
                  lower_bound: 1,
                  upper_bound: 1,
                  type: "vehicle"
                }
              }
            }
          }
        }

        node1 = %Paradigm.Graph.Node{id: "node1", class: "cow", data: %{}}

        node2 = %Paradigm.Graph.Node{
          id: "node2",
          class: "garage",
          data: %{"vehicleRef" => %Paradigm.Graph.Node.Ref{id: "node1"}}
        }

        graph = build_graph([node1, node2])

        assert %Paradigm.Conformance.Result{
                 issues: [
                   %Paradigm.Conformance.Issue{
                     property: "vehicleRef",
                     kind: :references_wrong_class,
                     details: %{class: "cow"},
                     node_id: "node2"
                   }
                 ]
               } = Paradigm.Conformance.check_graph(graph, paradigm)
      end

      test "validates valid reference to correct class" do
        paradigm = %Paradigm{
          classes: %{
            "vehicle" => %Paradigm.Class{
              name: "Vehicle",
              properties: %{}
            },
            "truck" => %Paradigm.Class{
              name: "Truck",
              super_classes: ["vehicle"],
              properties: %{}
            },
            "garage" => %Paradigm.Class{
              name: "Garage",
              properties: %{
                "vehicleRef" => %Paradigm.Property{
                  name: "vehicleRef",
                  lower_bound: 1,
                  upper_bound: 1,
                  type: "vehicle"
                }
              }
            }
          }
        }

        # Test direct class match
        node1 = %Paradigm.Graph.Node{id: "node1", class: "vehicle", data: %{}}

        node2 = %Paradigm.Graph.Node{
          id: "node2",
          class: "garage",
          data: %{"vehicleRef" => %Paradigm.Graph.Node.Ref{id: "node1"}}
        }

        graph1 = build_graph([node1, node2])

        Paradigm.Conformance.assert_conforms(graph1, paradigm)

        # Test subclass match
        truck_node = %Paradigm.Graph.Node{id: "node1", class: "truck", data: %{}}

        garage_node = %Paradigm.Graph.Node{
          id: "node2",
          class: "garage",
          data: %{"vehicleRef" => %Paradigm.Graph.Node.Ref{id: "node1"}}
        }

        graph2 = build_graph([truck_node, garage_node])

        Paradigm.Conformance.assert_conforms(graph2, paradigm)
      end

      test "detects reference to nonexistent node" do
        paradigm = %Paradigm{
          classes: %{
            "vehicle" => %Paradigm.Class{
              name: "Vehicle",
              properties: %{}
            },
            "garage" => %Paradigm.Class{
              name: "Garage",
              properties: %{
                "vehicleRef" => %Paradigm.Property{
                  name: "vehicleRef",
                  lower_bound: 1,
                  upper_bound: 1,
                  type: "vehicle"
                }
              }
            }
          }
        }

        node = %Paradigm.Graph.Node{
          id: "node1",
          class: "garage",
          data: %{"vehicleRef" => %Paradigm.Graph.Node.Ref{id: "nonexistent_node"}}
        }

        graph = build_graph(node)

        assert %Paradigm.Conformance.Result{
                 issues: [
                   %Paradigm.Conformance.Issue{
                     property: "vehicleRef",
                     kind: :references_missing_node,
                     details: %{referenced_id: "nonexistent_node"},
                     node_id: "node1"
                   }
                 ]
               } = Paradigm.Conformance.check_graph(graph, paradigm)
      end

      test "validates multiple references in collection" do
        paradigm = %Paradigm{
          classes: %{
            "vehicle" => %Paradigm.Class{
              name: "Vehicle",
              properties: %{}
            },
            "garage" => %Paradigm.Class{
              name: "Garage",
              properties: %{
                "vehicleRefs" => %Paradigm.Property{
                  name: "vehicleRefs",
                  lower_bound: 0,
                  upper_bound: :infinity,
                  type: "vehicle"
                }
              }
            }
          }
        }

        node1 = %Paradigm.Graph.Node{id: "node1", class: "vehicle", data: %{}}
        node2 = %Paradigm.Graph.Node{id: "node2", class: "vehicle", data: %{}}

        node3 = %Paradigm.Graph.Node{
          id: "node3",
          class: "garage",
          data: %{
            "vehicleRefs" => [
              %Paradigm.Graph.Node.Ref{id: "node1"},
              %Paradigm.Graph.Node.Ref{id: "node2"}
            ]
          }
        }

        graph =
          build_graph(node1)
          |> Paradigm.Graph.insert_node(node2)
          |> Paradigm.Graph.insert_node(node3)

        Paradigm.Conformance.assert_conforms(graph, paradigm)
      end

      test "validates mixed references and dangling references in collection" do
        paradigm = %Paradigm{
          classes: %{
            "vehicle" => %Paradigm.Class{
              name: "Vehicle",
              properties: %{}
            },
            "garage" => %Paradigm.Class{
              name: "Garage",
              properties: %{
                "vehicleRefs" => %Paradigm.Property{
                  name: "vehicleRefs",
                  lower_bound: 0,
                  upper_bound: :infinity,
                  type: "vehicle"
                }
              }
            }
          }
        }

        node1 = %Paradigm.Graph.Node{id: "node1", class: "vehicle", data: %{}}

        node2 = %Paradigm.Graph.Node{
          id: "node2",
          class: "garage",
          data: %{
            "vehicleRefs" => [
              %Paradigm.Graph.Node.Ref{id: "node1"},
              %Paradigm.Graph.Node.Ref{id: "missing_node"}
            ]
          }
        }

        graph =
          build_graph(node1)
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
               } = Paradigm.Conformance.check_graph(graph, paradigm)
      end

      test "detects non-reference value for reference property" do
        paradigm = %Paradigm{
          classes: %{
            "vehicle" => %Paradigm.Class{
              name: "Vehicle",
              properties: %{}
            },
            "garage" => %Paradigm.Class{
              name: "Garage",
              properties: %{
                "vehicleRef" => %Paradigm.Property{
                  name: "vehicleRef",
                  lower_bound: 1,
                  upper_bound: 1,
                  type: "vehicle"
                }
              }
            }
          }
        }

        # Property should contain %Paradigm.Graph.Node.Ref{} but has string instead
        node = %Paradigm.Graph.Node{
          id: "node1",
          class: "garage",
          # Should be %Paradigm.Graph.Node.Ref{id: "..."}
          data: %{"vehicleRef" => "not_a_reference"}
        }

        graph = build_graph(node)

        assert %Paradigm.Conformance.Result{
                 issues: [
                   %Paradigm.Conformance.Issue{
                     property: "vehicleRef",
                     kind: :expected_reference,
                     details: %{actual_type: "string"},
                     node_id: "node1"
                   }
                 ]
               } = Paradigm.Conformance.check_graph(graph, paradigm)
      end

      test "validates external reference to MOF primitive type" do
        paradigm = %Paradigm{
          primitive_types: %{
            "boolean" => %Paradigm.PrimitiveType{name: "Boolean"}
          },
          classes: %{
            "property" => %Paradigm.Class{
              name: "Property",
              properties: %{
                "type" => %Paradigm.Property{
                  name: "type",
                  lower_bound: 1,
                  upper_bound: 1,
                  type: "boolean"
                }
              }
            }
          }
        }

        # External reference to MOF Boolean primitive type.
        # Not that there is anything special about it.
        node = %Paradigm.Graph.Node{
          id: "node1",
          class: "property",
          data: %{
            "type" => %Paradigm.Graph.Node.ExternalRef{
              href: "http://schema.omg.org/spec/MOF/2.0/emof.xml#Boolean",
              type: "emof:PrimitiveType"
            }
          }
        }

        graph = build_graph(node)

        Paradigm.Conformance.assert_conforms(graph, paradigm)
      end
    end
  end
end
