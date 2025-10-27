defmodule Paradigm.Builtin.Filesystem do
  @moduledoc """
  The filesystem model.
  """
  alias Paradigm.{Package, Class, Property, PrimitiveType}

  def definition do
    %Paradigm{
      name: "Filesystem",
      description: "Describes file/folder structure including file contents.",
      primitive_types: %{"string" => %PrimitiveType{name: "String"}},
      packages: %{
        "filesystem_package" => %Package{
          name: "filesystem",
          uri: "http://example.org/filesystem",
          nested_packages: [],
          owned_types: ["node", "file", "folder"]
        }
      },
      classes: %{
        "file" => %Class{
          name: "File",
          is_abstract: false,
          properties: %{
            "contents" => %Property{
              name: "contents",
              type: "string",
              position: 0
            },
            "extension" => %Property{
              name: "extension",
              type: "string",
              position: 1
            }
          },
          super_classes: ["node"]
        },
        "folder" => %Class{
          name: "Folder",
          is_abstract: false,
          properties: %{
            "children" => %Property{
              name: "children",
              type: "node",
              is_ordered: true,
              is_composite: true,
              lower_bound: 0,
              upper_bound: :infinity,
              position: 0
            }
          },
          super_classes: ["node"]
        },
        "node" => %Class{
          name: "Node",
          is_abstract: true,
          properties: %{
            "name" => %Property{
              name: "name",
              type: "string",
              position: 0
            },
            "parent" => %Property{
              name: "parent",
              type: "folder",
              is_ordered: false,
              is_composite: false,
              lower_bound: 0,
              upper_bound: 1,
              position: 1
            }
          },
          super_classes: []
        }
      },
      enumerations: %{}
    }
  end
end
