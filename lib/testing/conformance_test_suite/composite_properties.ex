defmodule Paradigm.Conformance.TestSuite.CompositeProperties do
  defmacro __using__(_opts) do
    quote do
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

        part1 = %Paradigm.Graph.Node{
          id: "part1",
          class: "part",
          owned_by: "container1",
          data: %{}
        }

        part2 = %Paradigm.Graph.Node{
          id: "part2",
          class: "part",
          owned_by: "container1",
          data: %{}
        }

        container = %Paradigm.Graph.Node{
          id: "container1",
          class: "container",
          data: %{
            "compositeParts" => [
              %Paradigm.Graph.Node.Ref{id: "part1", composite: true},
              %Paradigm.Graph.Node.Ref{id: "part2", composite: true}
            ]
          }
        }

        graph =
          build_graph(part1)
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

        node = %Paradigm.Graph.Node{
          id: "node1",
          class: "class1",
          data: %{"invalidComposite" => ["value1", "value2"]}
        }

        graph = build_graph(node)

        assert %Paradigm.Conformance.Result{
                 issues: [
                   %Paradigm.Conformance.Issue{
                     property: "invalidComposite",
                     kind: :composite_primitive_type,
                     details: %{type: "string"},
                     node_id: "node1"
                   }
                 ]
               } = Paradigm.Conformance.check_graph(graph, paradigm)
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
        part1 = %Paradigm.Graph.Node{
          id: "part1",
          class: "part",
          data: %{},
          owned_by: "container1"
        }

        container1 = %Paradigm.Graph.Node{
          id: "container1",
          class: "container1",
          data: %{"parts" => [%Paradigm.Graph.Node.Ref{id: "part1", composite: true}]}
        }

        container2 = %Paradigm.Graph.Node{
          id: "container2",
          class: "container2",
          data: %{"parts" => [%Paradigm.Graph.Node.Ref{id: "part1", composite: true}]}
        }

        graph =
          build_graph(part1)
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
               } = Paradigm.Conformance.check_graph(graph, paradigm)
      end

      test "detects composite property without composite reference flag" do
        paradigm = %Paradigm{
          classes: %{
            "container" => %Paradigm.Class{
              name: "Container",
              owned_attributes: ["container_parts"]
            },
            "part" => %Paradigm.Class{
              name: "Part",
              owned_attributes: []
            }
          },
          properties: %{
            "container_parts" => %Paradigm.Property{
              name: "parts",
              is_composite: true,
              lower_bound: 1,
              upper_bound: :infinity,
              type: "part"
            }
          }
        }

        # Composite property but reference lacks composite: true flag
        part1 = %Paradigm.Graph.Node{
          id: "part1",
          class: "part",
          data: %{},
          owned_by: "container1"
        }

        container = %Paradigm.Graph.Node{
          id: "container1",
          class: "container",
          data: %{"parts" => [%Paradigm.Graph.Node.Ref{id: "part1", composite: false}]}
        }

        graph =
          build_graph(part1)
          |> Paradigm.Graph.insert_node(container)

        assert %Paradigm.Conformance.Result{
                 issues: [
                   %Paradigm.Conformance.Issue{
                     property: "parts",
                     kind: :composite_reference_without_flag,
                     details: %{referenced_id: "part1"},
                     node_id: "container1"
                   }
                 ]
               } = Paradigm.Conformance.check_graph(graph, paradigm)
      end

      test "detects node missing owned_by flag in composite relationship" do
        paradigm = %Paradigm{
          classes: %{
            "container" => %Paradigm.Class{
              name: "Container",
              owned_attributes: ["container_parts"]
            },
            "part" => %Paradigm.Class{
              name: "Part",
              owned_attributes: []
            }
          },
          properties: %{
            "container_parts" => %Paradigm.Property{
              name: "parts",
              is_composite: true,
              lower_bound: 1,
              upper_bound: :infinity,
              type: "part"
            }
          }
        }

        # Node is owned in composite relationship but lacks owned_by field
        part1 = %Paradigm.Graph.Node{id: "part1", class: "part", data: %{}, owned_by: nil}

        container = %Paradigm.Graph.Node{
          id: "container1",
          class: "container",
          data: %{"parts" => [%Paradigm.Graph.Node.Ref{id: "part1", composite: true}]}
        }

        graph =
          build_graph(part1)
          |> Paradigm.Graph.insert_node(container)

        assert %Paradigm.Conformance.Result{
                 issues: [
                   %Paradigm.Conformance.Issue{
                     property: "parts",
                     kind: :composite_owned_node_without_owner,
                     details: %{owner_node_id: "container1"},
                     node_id: "part1"
                   }
                 ]
               } = Paradigm.Conformance.check_graph(graph, paradigm)
      end

      test "validates correct composite relationship with proper flags" do
        paradigm = %Paradigm{
          classes: %{
            "container" => %Paradigm.Class{
              name: "Container",
              owned_attributes: ["container_parts"]
            },
            "part" => %Paradigm.Class{
              name: "Part",
              owned_attributes: []
            }
          },
          properties: %{
            "container_parts" => %Paradigm.Property{
              name: "parts",
              is_composite: true,
              lower_bound: 1,
              upper_bound: :infinity,
              type: "part"
            }
          }
        }

        # Both composite flag on reference and owned_by flag on node are set correctly
        part1 = %Paradigm.Graph.Node{
          id: "part1",
          class: "part",
          data: %{},
          owned_by: "container1"
        }

        container = %Paradigm.Graph.Node{
          id: "container1",
          class: "container",
          data: %{"parts" => [%Paradigm.Graph.Node.Ref{id: "part1", composite: true}]}
        }

        graph = build_graph([part1, container])

        Paradigm.Conformance.assert_conforms(graph, paradigm)
      end
    end
  end
end
