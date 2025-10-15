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
          owned_types: ["registered_graph", "instantiation", "transform", "transform_instance"]
        }
      },
      classes: %{
        "registered_graph" => %Class{
          name: "RegisteredGraph",
          owned_attributes: ["graph_name", "graph"]
        },
        "instantiation" => %Class{
          name: "Instantiation",
          owned_attributes: [
            "instantiation_paradigm",
            "instantiation_instance",
            "instantiation_conformance_result"
          ]
        },
        "transform" => %Class{
          name: "Transform",
          super_classes: [],
          owned_attributes: [
            "transform_name",
            "transform_transform",
            "source_paradigm",
            "target_paradigm"
          ]
        },
        "transform_instance" => %Class{
          name: "TransformInstance",
          owned_attributes: [
            "used_transform",
            "transform_source",
            "transform_target",
            "transform_errors",
            "transform_warnings"
          ]
        }
      },
      properties: %{
        "graph" => %Property{
          name: "graph",
          type: "paradigm_graph"
        },
        "graph_name" => %Property{
          name: "name",
          type: "string"
        },
        "instantiation_paradigm" => %Property{
          name: "paradigm",
          type: "registered_graph"
        },
        "instantiation_instance" => %Property{
          name: "instance",
          type: "registered_graph"
        },
        "instantiation_conformance_result" => %Property{
          name: "conformance_result",
          type: "conformance_result",
          lower_bound: 0,
          upper_bound: 1
        },
        "transform_name" => %Property{
          name: "name",
          type: "string"
        },
        "transform_transform" => %Property{
          name: "transform",
          type: "paradigm_transform"
        },
        "source_paradigm" => %Property{
          name: "source",
          type: "registered_graph"
        },
        "target_paradigm" => %Property{
          name: "target",
          type: "registered_graph"
        },
        "used_transform" => %Property{
          name: "transform",
          type: "transform"
        },
        "transform_source" => %Property{
          name: "source",
          type: "registered_graph"
        },
        "transform_target" => %Property{
          name: "target",
          type: "registered_graph",
          lower_bound: 0
        },
        "transform_errors" => %Property{
          name: "errors",
          type: "string",
          lower_bound: 0,
          upper_bound: :infinity
        },
        "transform_warnings" => %Property{
          name: "warnings",
          type: "string",
          lower_bound: 0,
          upper_bound: :infinity
        }
      }
    }
  end
end
