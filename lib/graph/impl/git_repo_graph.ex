defmodule Paradigm.Graph.GitRepoGraph do
  @moduledoc """
  A graph implementation that adapts git repos to graph nodes.
  Uses the GitRepo canonical model to represent repositories, commits, branches, and tags as nodes.
  """

  defstruct [:root, :metadata, :current_revision]

  def new(opts \\ []) do
    root = Keyword.get(opts, :root, "/")
    current_revision = Keyword.get(opts, :current_revision, "HEAD")

    %__MODULE__{
      root: Path.expand(root),
      current_revision: current_revision,
      metadata: Keyword.take(opts, [:name, :description])
    }
  end

  def new(root_path, opts) when is_binary(root_path) and is_list(opts) do
    current_revision = Keyword.get(opts, :current_revision, "HEAD")

    %__MODULE__{
      root: Path.expand(root_path),
      current_revision: current_revision,
      metadata: Keyword.take(opts, [:name, :description])
    }
  end
end

defimpl Paradigm.Graph, for: Paradigm.Graph.GitRepoGraph do
  alias Paradigm.Graph.Node

  @impl true
  def get_name(%{metadata: metadata}) do
    Keyword.get(metadata, :name)
  end

  @impl true
  def get_description(%{metadata: metadata}) do
    Keyword.get(metadata, :description)
  end

  @impl true
  def get_content_hash(%{root: root_path}) do
    case run_git_cmd(["rev-parse", "HEAD"], root_path) do
      {output, 0} ->
        # Use the current HEAD commit hash as the primary content identifier
        head_hash = String.trim(output)

        # Also include branch and tag state for a more complete hash
        branches_hash = get_all_branches(root_path) |> Enum.sort() |> :erlang.term_to_binary()
        tags_hash = get_all_tags(root_path) |> Enum.sort() |> :erlang.term_to_binary()

        combined = head_hash <> Base.encode16(:crypto.hash(:sha256, branches_hash <> tags_hash))

        Base.encode16(:crypto.hash(:sha256, combined))
        |> String.slice(-8..-1)

      _ ->
        # Fallback for non-git repos or repos without commits
        repo_state = %{
          branches: get_all_branches(root_path),
          tags: get_all_tags(root_path),
          path: root_path
        }

        Base.encode16(:crypto.hash(:sha256, :erlang.term_to_binary(repo_state)))
        |> String.slice(-8..-1)
    end
  end

  @impl true
  def get_all_nodes(%{root: root_path}) do
    case is_git_repo?(root_path) do
      true -> collect_all_git_nodes(root_path)
      false -> []
    end
  end

  @impl true
  def stream_all_nodes(%{root: root_path} = git_graph) do
    case is_git_repo?(root_path) do
      true ->
        Stream.concat([
          # Repository node
          ["repository"]
          |> Stream.map(&get_node(git_graph, &1)),

          # Stream commits
          get_all_commit_hashes(root_path)
          |> Stream.map(&("commit:" <> &1))
          |> Stream.map(&get_node(git_graph, &1)),

          # Stream branches
          get_all_branches(root_path)
          |> Stream.map(&("branch:" <> &1))
          |> Stream.map(&get_node(git_graph, &1)),

          # Stream tags
          get_all_tags(root_path)
          |> Stream.map(&("tag:" <> &1))
          |> Stream.map(&get_node(git_graph, &1))
        ])
        |> Stream.reject(&is_nil/1)

      false ->
        []
        |> Stream.map(& &1)
    end
  end

  @impl true
  def get_all_classes(_git_repo_graph) do
    ["repository", "commit", "branch", "tag"]
  end

  @impl true
  def get_node(%{root: root_path}, node_id) do
    cond do
      node_id == "repository" ->
        %Node{
          id: node_id,
          class: "repository",
          data: build_repository_data(root_path),
          owned_by: nil
        }

      String.starts_with?(node_id, "commit:") ->
        commit_hash = String.replace_prefix(node_id, "commit:", "")

        case get_commit_info(root_path, commit_hash) do
          nil ->
            nil

          commit_info ->
            %Node{
              id: node_id,
              class: "commit",
              data: build_commit_data(root_path, commit_info),
              owned_by: "repository"
            }
        end

      String.starts_with?(node_id, "branch:") ->
        branch_name = String.replace_prefix(node_id, "branch:", "")

        case get_branch_info(root_path, branch_name) do
          nil ->
            nil

          branch_info ->
            %Node{
              id: node_id,
              class: "branch",
              data: build_branch_data(branch_info),
              owned_by: "repository"
            }
        end

      String.starts_with?(node_id, "tag:") ->
        tag_name = String.replace_prefix(node_id, "tag:", "")

        case get_tag_info(root_path, tag_name) do
          nil ->
            nil

          tag_info ->
            %Node{
              id: node_id,
              class: "tag",
              data: build_tag_data(tag_info),
              owned_by: "repository"
            }
        end

      true ->
        nil
    end
  end

  @impl true
  def get_all_nodes_of_class(git_graph, class_id) when is_binary(class_id) do
    get_all_nodes_of_class(git_graph, [class_id])
  end

  @impl true
  def get_all_nodes_of_class(%{root: root_path}, class_ids) when is_list(class_ids) do
    all_nodes = collect_all_git_nodes(root_path)

    Enum.filter(all_nodes, fn node_id ->
      node = get_node(%{root: root_path}, node_id)
      node && node.class in class_ids
    end)
  end

  @impl true
  def insert_node(%{root: root_path} = git_graph, %Node{
        id: node_id,
        class: class_id,
        data: _node_data
      }) do
    case class_id do
      "repository" ->
        # Initialize git repository
        run_git_cmd(["init"], root_path)

      "commit" ->
        {:error, "Cannot insert commits directly"}

      "branch" ->
        branch_name = String.replace_prefix(node_id, "branch:", "")
        run_git_cmd(["checkout", "-b", branch_name], root_path)

      "tag" ->
        tag_name = String.replace_prefix(node_id, "tag:", "")
        run_git_cmd(["tag", tag_name], root_path)

      _ ->
        {:error, "Unsupported class: #{class_id}"}
    end

    git_graph
  end

  @impl true
  def insert_nodes(git_graph, nodes) when is_list(nodes) do
    Enum.reduce(nodes, git_graph, fn node, acc ->
      insert_node(acc, node)
    end)
  end

  @impl true
  def follow_reference(%{root: root_path} = git_graph, node_id, reference_property) do
    case {node_id, reference_property} do
      {"repository", "branches"} ->
        get_all_nodes_of_class(git_graph, "branch")
        |> Enum.map(&get_node(git_graph, &1))
        |> Enum.reject(&is_nil/1)

      {"repository", "tags"} ->
        get_all_nodes_of_class(git_graph, "tag")
        |> Enum.map(&get_node(git_graph, &1))
        |> Enum.reject(&is_nil/1)

      {"repository", "commits"} ->
        get_all_nodes_of_class(git_graph, "commit")
        |> Enum.map(&get_node(git_graph, &1))
        |> Enum.reject(&is_nil/1)

      {branch_id, "head"} ->
        if String.starts_with?(branch_id, "branch:") do
          branch_name = String.replace_prefix(branch_id, "branch:", "")

          case get_branch_head(root_path, branch_name) do
            nil -> nil
            commit_hash -> get_node(git_graph, "commit:#{commit_hash}")
          end
        else
          nil
        end

      {tag_id, "commit"} ->
        if String.starts_with?(tag_id, "tag:") do
          tag_name = String.replace_prefix(tag_id, "tag:", "")

          case get_tag_commit(root_path, tag_name) do
            nil -> nil
            commit_hash -> get_node(git_graph, "commit:#{commit_hash}")
          end
        else
          nil
        end

      {commit_id, "parents"} ->
        if String.starts_with?(commit_id, "commit:") do
          commit_hash = String.replace_prefix(commit_id, "commit:", "")

          get_commit_parents(root_path, commit_hash)
          |> Enum.map(&get_node(git_graph, "commit:#{&1}"))
          |> Enum.reject(&is_nil/1)
        else
          nil
        end

      _ ->
        nil
    end
  end

  # Private helper functions

  defp run_git_cmd(args, root_path) do
    System.cmd("git", args, cd: root_path, stderr_to_stdout: true)
  end

  defp is_git_repo?(root_path) do
    File.exists?(Path.join(root_path, ".git"))
  end

  defp collect_all_git_nodes(root_path) do
    nodes = ["repository"]

    # Add all commits
    commit_nodes =
      get_all_commit_hashes(root_path)
      |> Enum.map(&("commit:" <> &1))

    # Add all branches
    branch_nodes =
      get_all_branches(root_path)
      |> Enum.map(&("branch:" <> &1))

    # Add all tags
    tag_nodes =
      get_all_tags(root_path)
      |> Enum.map(&("tag:" <> &1))

    nodes ++ commit_nodes ++ branch_nodes ++ tag_nodes
  end

  defp build_repository_data(root_path) do
    repo_name = Path.basename(root_path)

    %{
      "name" => repo_name,
      "branches" =>
        get_all_branches(root_path) |> Enum.map(&%Node.Ref{id: "branch:#{&1}", composite: true}),
      "tags" => get_all_tags(root_path) |> Enum.map(&%Node.Ref{id: "tag:#{&1}", composite: true}),
      "commits" =>
        get_all_commit_hashes(root_path)
        |> Enum.map(&%Node.Ref{id: "commit:#{&1}", composite: true})
    }
  end

  defp build_commit_data(root_path, commit_info) do
    filesystem_graph = build_filesystem_graph_for_commit(root_path, commit_info.hash)

    parent_refs =
      get_commit_parents(root_path, commit_info.hash)
      |> Enum.map(&%Node.Ref{id: "commit:#{&1}", composite: false})

    %{
      "hash" => commit_info.hash,
      "message" => commit_info.message,
      "author" => commit_info.author,
      "date" => commit_info.date,
      "parents" => parent_refs,
      "filesystem" => filesystem_graph
    }
  end

  defp build_branch_data(branch_info) do
    head_ref = %Node.Ref{id: "commit:#{branch_info.head}", composite: false}

    %{
      "name" => branch_info.name,
      "head" => head_ref
    }
  end

  defp build_tag_data(tag_info) do
    commit_ref = %Node.Ref{id: "commit:#{tag_info.commit}", composite: false}

    %{
      "name" => tag_info.name,
      "commit" => commit_ref
    }
  end

  defp get_all_commit_hashes(root_path) do
    case run_git_cmd(["log", "--all", "--format=%H"], root_path) do
      {output, 0} ->
        output
        |> String.split("\n", trim: true)

      _ ->
        []
    end
  end

  defp get_all_branches(root_path) do
    case run_git_cmd(["branch", "-a", "--format=%(refname:short)"], root_path) do
      {output, 0} ->
        output
        |> String.split("\n", trim: true)
        |> Enum.reject(&String.starts_with?(&1, "origin/"))

      _ ->
        []
    end
  end

  defp get_all_tags(root_path) do
    case run_git_cmd(["tag", "-l"], root_path) do
      {output, 0} ->
        output
        |> String.split("\n", trim: true)

      _ ->
        []
    end
  end

  defp get_commit_info(root_path, commit_hash) do
    case run_git_cmd(["show", "--format=%H|%s|%an|%ai", "--no-patch", commit_hash], root_path) do
      {output, 0} ->
        [hash, message, author, date] = String.split(String.trim(output), "|", parts: 4)
        %{hash: hash, message: message, author: author, date: date}

      _ ->
        nil
    end
  end

  defp get_branch_info(root_path, branch_name) do
    case get_branch_head(root_path, branch_name) do
      nil -> nil
      head_hash -> %{name: branch_name, head: head_hash}
    end
  end

  defp get_tag_info(root_path, tag_name) do
    case get_tag_commit(root_path, tag_name) do
      nil -> nil
      commit_hash -> %{name: tag_name, commit: commit_hash}
    end
  end

  defp get_branch_head(root_path, branch_name) do
    case run_git_cmd(["rev-parse", branch_name], root_path) do
      {output, 0} -> String.trim(output)
      _ -> nil
    end
  end

  defp get_tag_commit(root_path, tag_name) do
    case run_git_cmd(["rev-list", "-n", "1", tag_name], root_path) do
      {output, 0} -> String.trim(output)
      _ -> nil
    end
  end

  defp get_commit_parents(root_path, commit_hash) do
    case run_git_cmd(["rev-list", "--parents", "-n", "1", commit_hash], root_path) do
      {output, 0} ->
        [_commit | parents] = String.split(String.trim(output), " ")
        parents

      _ ->
        []
    end
  end

  defp build_filesystem_graph_for_commit(root_path, commit_hash) do
    # Create a temporary directory to checkout the commit
    temp_dir = System.tmp_dir!() |> Path.join("git_checkout_#{:rand.uniform(1_000_000)}")

    try do
      # Clone and checkout the specific commit in temp directory
      case run_git_cmd(["clone", root_path, temp_dir], System.tmp_dir!()) do
        {_, 0} ->
          case run_git_cmd(["checkout", commit_hash], temp_dir) do
            {_, 0} ->
              # Create a filesystem graph for this checkout
              Paradigm.Graph.FilesystemGraph.new(root: temp_dir)

            _ ->
              %{}
          end

        _ ->
          %{}
      end
    after
      File.rm_rf(temp_dir)
    end
  end
end
