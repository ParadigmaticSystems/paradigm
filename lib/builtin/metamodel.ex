defmodule Paradigm.Builtin.Metamodel do
  @moduledoc """
  The canonical self-model of the Paradigm structure.
  """
  alias Paradigm.{PrimitiveType, Package, Class, Property}

  def definition do
    %Paradigm{
      name: "Metamodel",
      description: "Paradigm self-model",
      primitive_types: %{
        "boolean" => %PrimitiveType{name: "Boolean"},
        "integer" => %PrimitiveType{name: "Integer"},
        "string" => %PrimitiveType{name: "String"}
      },
      packages: %{
        "metamodel_package" => %Package{
          name: "metamodel",
          uri: "http://example.org/metamodel",
          nested_packages: [],
          owned_types: ["type", "class", "primitive_type", "enumeration", "property", "package"]
        }
      },
      classes: %{
        "class" => %Class{
          name: "Class",
          is_abstract: false,
          properties: %{
            "is_abstract" => %Property{
              name: "is_abstract",
              type: "boolean",
              default_value: false,
              position: 0
            },
            "owned_attributes" => %Property{
              name: "owned_attributes",
              type: "property",
              is_ordered: true,
              is_composite: true,
              lower_bound: 0,
              upper_bound: :infinity,
              default_value: [],
              position: 1
            },
            "super_classes" => %Property{
              name: "super_classes",
              type: "class",
              is_ordered: false,
              is_composite: false,
              lower_bound: 0,
              upper_bound: :infinity,
              default_value: [],
              position: 2
            }
          },
          super_classes: ["type"]
        },
        "enumeration" => %Class{
          name: "Enumeration",
          is_abstract: false,
          properties: %{
            "literals" => %Property{
              name: "literals",
              type: "string",
              is_ordered: true,
              is_composite: false,
              lower_bound: 0,
              upper_bound: :infinity,
              default_value: [],
              position: 0
            }
          },
          super_classes: ["type"]
        },
        "package" => %Class{
          name: "Package",
          is_abstract: false,
          properties: %{
            "name" => %Property{
              name: "name",
              type: "string",
              position: 0
            },
            "uri" => %Property{
              name: "uri",
              type: "string",
              position: 1
            },
            "nested_packages" => %Property{
              name: "nested_packages",
              type: "package",
              is_ordered: false,
              is_composite: true,
              lower_bound: 0,
              upper_bound: :infinity,
              default_value: [],
              position: 2
            },
            "owned_types" => %Property{
              name: "owned_types",
              type: "type",
              is_ordered: false,
              is_composite: true,
              lower_bound: 0,
              upper_bound: :infinity,
              default_value: [],
              position: 3
            }
          },
          super_classes: []
        },
        "primitive_type" => %Class{
          name: "PrimitiveType",
          is_abstract: false,
          properties: %{},
          super_classes: ["type"]
        },
        "property" => %Class{
          name: "Property",
          is_abstract: false,
          properties: %{
            "name" => %Property{
              name: "name",
              type: "string",
              position: 0
            },
            "type" => %Property{
              name: "type",
              type: "type",
              is_ordered: false,
              is_composite: false,
              lower_bound: 1,
              upper_bound: 1,
              position: 1
            },
            "is_ordered" => %Property{
              name: "is_ordered",
              type: "boolean",
              default_value: false,
              position: 2
            },
            "is_composite" => %Property{
              name: "is_composite",
              type: "boolean",
              default_value: false,
              position: 3
            },
            "lower_bound" => %Property{
              name: "lower_bound",
              type: "integer",
              default_value: 1,
              position: 4
            },
            "upper_bound" => %Property{
              name: "upper_bound",
              type: "integer",
              position: 5
            },
            "default_value" => %Property{
              name: "default_value",
              type: "string",
              lower_bound: 0,
              upper_bound: 1,
              position: 6
            },
            "position" => %Property{
              name: "position",
              type: "integer",
              default_value: 0,
              position: 7
            }
          },
          super_classes: []
        },
        "type" => %Class{
          name: "Type",
          is_abstract: true,
          properties: %{
            "name" => %Property{
              name: "name",
              type: "string",
              position: 0
            }
          },
          super_classes: []
        }
      },
      enumerations: %{}
    }
  end
end
