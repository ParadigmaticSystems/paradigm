defmodule Paradigm.Canonical.Metamodel do
  @moduledoc """
  The canonical self-model of the Paradigm structure.
  """
  alias Paradigm.{PrimitiveType, Package, Class, Property}

  def definition do
    %Paradigm{
      name: "MetaModel",
      description: "Paradigm self-model",
      primitive_types: %{
        "boolean" => %PrimitiveType{name: "Boolean"},
        "float" => %PrimitiveType{name: "Float"},
        "double" => %PrimitiveType{name: "Double"},
        "integer" => %PrimitiveType{name: "Integer"},
        "string" => %PrimitiveType{name: "String"},
        "void" => %PrimitiveType{name: "Void"}
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
          owned_attributes: ["class_is_abstract", "class_owned_attributes", "class_super_classes"],
          super_classes: ["type"]
        },
        "enumeration" => %Class{
          name: "Enumeration",
          is_abstract: false,
          owned_attributes: ["enumeration_literals"],
          super_classes: ["type"]
        },
        "package" => %Class{
          name: "Package",
          is_abstract: false,
          owned_attributes: [
            "package_name",
            "package_uri",
            "package_nested_packages",
            "package_owned_types"
          ],
          super_classes: []
        },
        "primitive_type" => %Class{
          name: "PrimitiveType",
          is_abstract: false,
          owned_attributes: [],
          super_classes: ["type"]
        },
        "property" => %Class{
          name: "Property",
          is_abstract: false,
          owned_attributes: [
            "property_name",
            "property_type",
            "property_is_ordered",
            "property_is_composite",
            "property_lower_bound",
            "property_upper_bound",
            "property_default_value"
          ],
          super_classes: []
        },
        "type" => %Class{
          name: "Type",
          is_abstract: true,
          owned_attributes: ["type_name"],
          super_classes: []
        }
      },
      enumerations: %{},
      properties: %{
        "class_is_abstract" => %Property{
          name: "is_abstract",
          type: "boolean",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1,
          default_value: false
        },
        "class_owned_attributes" => %Property{
          name: "owned_attributes",
          type: "property",
          is_ordered: true,
          is_composite: true,
          lower_bound: 0,
          upper_bound: :infinity,
          default_value: []
        },
        "class_super_classes" => %Property{
          name: "super_classes",
          type: "class",
          is_ordered: false,
          is_composite: false,
          lower_bound: 0,
          upper_bound: :infinity,
          default_value: []
        },
        "enumeration_literal_name" => %Property{
          name: "name",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1,
          default_value: nil
        },
        "enumeration_literals" => %Property{
          name: "literals",
          type: "string",
          is_ordered: true,
          is_composite: false,
          lower_bound: 0,
          upper_bound: :infinity,
          default_value: []
        },
        "package_name" => %Property{
          name: "name",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1,
          default_value: nil
        },
        "package_nested_packages" => %Property{
          name: "nested_packages",
          type: "package",
          is_ordered: true,
          is_composite: true,
          lower_bound: 0,
          upper_bound: :infinity,
          default_value: []
        },
        "package_owned_types" => %Property{
          name: "owned_types",
          type: "class",
          is_ordered: true,
          is_composite: true,
          lower_bound: 0,
          upper_bound: :infinity,
          default_value: []
        },
        "package_uri" => %Property{
          name: "uri",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1,
          default_value: nil
        },
        "property_is_composite" => %Property{
          name: "is_composite",
          type: "boolean",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1,
          default_value: false
        },
        "property_is_ordered" => %Property{
          name: "is_ordered",
          type: "boolean",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1,
          default_value: false
        },
        "property_lower_bound" => %Property{
          name: "lower_bound",
          type: "integer",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1,
          default_value: 1
        },
        "property_name" => %Property{
          name: "name",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1,
          default_value: nil
        },
        "property_type" => %Property{
          name: "type",
          type: "type",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1,
          default_value: nil
        },
        "property_upper_bound" => %Property{
          name: "upper_bound",
          type: "integer",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1,
          default_value: 1
        },
        "property_default_value" => %Property{
          name: "default_value",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 0,
          upper_bound: 1,
          default_value: nil
        },
        "type_name" => %Property{
          name: "name",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1,
          default_value: nil
        }
      }
    }
  end
end
