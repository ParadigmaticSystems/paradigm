defmodule Paradigm.Builtin.GitRepo do
  @moduledoc """
  The git repo model.
  """
  alias Paradigm.{Package, Class, Property, PrimitiveType}

  def definition do
    %Paradigm{
      name: "GitRepo",
      description:
        "Describes git repository structure including commits, branches, and filesystem content at each revision.",
      primitive_types: %{
        "string" => %PrimitiveType{name: "String"},
        "graph" => %PrimitiveType{name: "Paradigm.Graph"}
      },
      packages: %{
        "git_package" => %Package{
          name: "git",
          uri: "http://example.org/git",
          nested_packages: [],
          owned_types: ["repository", "commit", "branch", "tag"]
        }
      },
      classes: %{
        "repository" => %Class{
          name: "Repository",
          is_abstract: false,
          properties: %{
            "name" => %Property{
              name: "name",
              type: "string",
              position: 0
            },
            "branches" => %Property{
              name: "branches",
              type: "branch",
              is_ordered: false,
              is_composite: true,
              lower_bound: 0,
              upper_bound: :infinity,
              position: 1
            },
            "tags" => %Property{
              name: "tags",
              type: "tag",
              is_ordered: false,
              is_composite: true,
              lower_bound: 0,
              upper_bound: :infinity,
              position: 2
            },
            "commits" => %Property{
              name: "commits",
              type: "commit",
              is_ordered: false,
              is_composite: true,
              lower_bound: 0,
              upper_bound: :infinity,
              position: 3
            }
          },
          super_classes: []
        },
        "commit" => %Class{
          name: "Commit",
          is_abstract: false,
          properties: %{
            "hash" => %Property{
              name: "hash",
              type: "string",
              position: 0
            },
            "message" => %Property{
              name: "message",
              type: "string",
              position: 1
            },
            "author" => %Property{
              name: "author",
              type: "string",
              position: 2
            },
            "date" => %Property{
              name: "date",
              type: "string",
              position: 3
            },
            "parents" => %Property{
              name: "parents",
              type: "commit",
              is_ordered: true,
              is_composite: false,
              lower_bound: 0,
              upper_bound: :infinity,
              position: 4
            },
            "filesystem" => %Property{
              name: "filesystem",
              type: "graph",
              position: 5
            }
          },
          super_classes: []
        },
        "branch" => %Class{
          name: "Branch",
          is_abstract: false,
          properties: %{
            "name" => %Property{
              name: "name",
              type: "string",
              position: 0
            },
            "head" => %Property{
              name: "head",
              type: "commit",
              is_ordered: false,
              is_composite: false,
              lower_bound: 1,
              upper_bound: 1,
              position: 1
            }
          },
          super_classes: []
        },
        "tag" => %Class{
          name: "Tag",
          is_abstract: false,
          properties: %{
            "name" => %Property{
              name: "name",
              type: "string",
              position: 0
            },
            "commit" => %Property{
              name: "commit",
              type: "commit",
              is_ordered: false,
              is_composite: false,
              lower_bound: 1,
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
