defmodule Paradigm.Canonical.Filesystem do
  @moduledoc """
  The filesystem model.
  """
  alias Paradigm.{Package, Class, Property, PrimitiveType}
  def definition do
    %Paradigm{
      name: "FileSystem",
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
          owned_attributes: ["file_contents", "file_extension"],
          super_classes: ["node"]
        },
        "folder" => %Class{
          name: "Folder",
          is_abstract: false,
          owned_attributes: ["folder_children"],
          super_classes: ["node"]
        },
        "node" => %Class{
          name: "Node",
          is_abstract: true,
          owned_attributes: ["node_name", "node_parent"],
          super_classes: []
        }
      },
      enumerations: %{},
      properties: %{
        "file_contents" => %Property{
          name: "contents",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "folder_children" => %Property{
          name: "children",
          type: "node",
          is_ordered: true,
          is_composite: true,
          lower_bound: 0,
          upper_bound: :infinity
        },
        "file_extension" => %Property{
          name: "extension",
          type: "string"
        },
        "node_name" => %Property{
          name: "name",
          type: "string"
        },
        "node_parent" => %Property{
          name: "parent",
          type: "folder",
          is_ordered: false,
          is_composite: false,
          lower_bound: 0,
          upper_bound: 1
        }
      }
    }
  end
end
