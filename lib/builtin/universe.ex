defmodule Paradigm.Builtin.Universe do
  @moduledoc """
  The paradigm system model
  """
  alias Paradigm.{Package, Class, Property, PrimitiveType}

  def definition do
    %Paradigm{
      name: "Universe",
      description:
        "A meta-paradigm in which graphs are primitive types, and we model the abstraction and transform relationships between them.",
      primitive_types: %{
        "string" => %PrimitiveType{name: "String"},
        "paradigm_graph" => %PrimitiveType{name: "Paradigm.Graph"},
        "paradigm_transform" => %PrimitiveType{name: "Paradigm.Transform"},
        "conformance_result" => %PrimitiveType{name: "Paradigm.Conformance.Result"}
      },
      packages: %{
        "universe" => %Package{
          name: "Universe",
          uri: "universe",
          owned_types: ["registered_graph", "transform", "transform_instance"]
        }
      },
      classes: %{
        "registered_graph" => %Class{
          name: "RegisteredGraph",
          properties: %{
            "name" => %Property{
              name: "name",
              type: "string",
              position: 0
            },
            "graph" => %Property{
              name: "graph",
              type: "paradigm_graph",
              position: 1
            },
            "paradigm" => %Property{
              name: "paradigm",
              type: "registered_graph",
              position: 2
            },
            "conformance_result" => %Property{
              name: "conformance_result",
              type: "conformance_result",
              lower_bound: 0,
              upper_bound: 1,
              position: 3
            }
          }
        },
        "transform" => %Class{
          name: "Transform",
          super_classes: [],
          properties: %{
            "name" => %Property{
              name: "name",
              type: "string",
              position: 0
            },
            "transform" => %Property{
              name: "transform",
              type: "paradigm_transform",
              position: 1
            },
            "source" => %Property{
              name: "source",
              type: "registered_graph",
              position: 2
            },
            "target" => %Property{
              name: "target",
              type: "registered_graph",
              position: 3
            }
          }
        },
        "transform_instance" => %Class{
          name: "TransformInstance",
          properties: %{
            "transform" => %Property{
              name: "transform",
              type: "transform",
              position: 0
            },
            "source" => %Property{
              name: "source",
              type: "registered_graph",
              position: 1
            },
            "target" => %Property{
              name: "target",
              type: "registered_graph",
              lower_bound: 0,
              position: 2
            },
            "errors" => %Property{
              name: "errors",
              type: "string",
              lower_bound: 0,
              upper_bound: :infinity,
              position: 3
            },
            "warnings" => %Property{
              name: "warnings",
              type: "string",
              lower_bound: 0,
              upper_bound: :infinity,
              position: 4
            }
          }
        }
      }
    }
  end
end
