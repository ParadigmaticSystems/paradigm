defmodule Paradigm.Builtin.GitRepo do
  @moduledoc """
  The git repo model.
  """
  alias Paradigm.{Package, Class, Property, PrimitiveType}
  def definition do
    %Paradigm{
      name: "GitRepo",
      description: "Describes git repository structure including commits, branches, and filesystem content at each revision.",
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
          owned_attributes: ["repo_name", "repo_branches", "repo_tags", "repo_commits"],
          super_classes: []
        },
        "commit" => %Class{
          name: "Commit",
          is_abstract: false,
          owned_attributes: ["commit_hash", "commit_message", "commit_author", "commit_date", "commit_parents", "commit_filesystem"],
          super_classes: []
        },
        "branch" => %Class{
          name: "Branch",
          is_abstract: false,
          owned_attributes: ["branch_name", "branch_head"],
          super_classes: []
        },
        "tag" => %Class{
          name: "Tag",
          is_abstract: false,
          owned_attributes: ["tag_name", "tag_commit"],
          super_classes: []
        }
      },
      enumerations: %{},
      properties: %{
        "repo_name" => %Property{
          name: "name",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "repo_branches" => %Property{
          name: "branches",
          type: "branch",
          is_ordered: false,
          is_composite: true,
          lower_bound: 0,
          upper_bound: :infinity
        },
        "repo_tags" => %Property{
          name: "tags",
          type: "tag",
          is_ordered: false,
          is_composite: true,
          lower_bound: 0,
          upper_bound: :infinity
        },
        "repo_commits" => %Property{
          name: "commits",
          type: "commit",
          is_ordered: false,
          is_composite: true,
          lower_bound: 0,
          upper_bound: :infinity
        },
        "commit_hash" => %Property{
          name: "hash",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "commit_message" => %Property{
          name: "message",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "commit_author" => %Property{
          name: "author",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "commit_date" => %Property{
          name: "date",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "commit_parents" => %Property{
          name: "parents",
          type: "commit",
          is_ordered: false,
          is_composite: false,
          lower_bound: 0,
          upper_bound: :infinity
        },
        "commit_filesystem" => %Property{
          name: "filesystem",
          type: "graph",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "branch_name" => %Property{
          name: "name",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "branch_head" => %Property{
          name: "head",
          type: "commit",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "tag_name" => %Property{
          name: "name",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "tag_commit" => %Property{
          name: "commit",
          type: "commit",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        }
      }
    }
  end
end
