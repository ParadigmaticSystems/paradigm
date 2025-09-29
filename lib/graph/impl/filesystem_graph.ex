defmodule Paradigm.Graph.FilesystemGraph do
  @moduledoc """
  A graph implementation that adapts filesystem objects to graph nodes.
  Uses the FileSystem canonical model to represent files and folders as nodes.
  """

  defstruct [:root, :metadata]

  def new(opts \\ []) do
    root = Keyword.get(opts, :root, "/")
    %__MODULE__{
      root: Path.expand(root),
      metadata: Keyword.take(opts, [:name, :description])
    }
  end

  def new(root_path, opts) when is_binary(root_path) and is_list(opts) do
    %__MODULE__{
      root: Path.expand(root_path),
      metadata: Keyword.take(opts, [:name, :description])
    }
  end
end

defimpl Paradigm.Graph, for: Paradigm.Graph.FilesystemGraph do
  alias Paradigm.Graph.Node

  @impl true
  def get_all_nodes(%{root: root_path}) do
    case File.exists?(root_path) do
      true -> collect_all_paths(root_path)
      false -> []
    end
  end

  @impl true
    def stream_all_nodes(%{root: root_path}) do
      case File.exists?(root_path) do
        true ->
          Stream.resource(
            fn -> {collect_all_paths(root_path), 0} end,
            fn {paths, index} ->
              if index >= length(paths) do
                {:halt, {paths, index}}
              else
                path = Enum.at(paths, index)
                case get_node(%{root: root_path}, path) do
                  nil -> {[], {paths, index + 1}}
                  node -> {[node], {paths, index + 1}}
                end
              end
            end,
            fn _ -> :ok end
          )
        false ->
          []
          |> Stream.map(& &1)
      end
    end

  @impl true
  def get_all_classes(_filesystem_graph) do
    ["file", "folder", "node"]
  end

  @impl true
  def get_node(%{root: root_path}, node_id) do
    full_path = resolve_path(root_path, node_id)

    case File.stat(full_path) do
      {:ok, %File.Stat{type: :regular}} ->
        parent_path = Path.dirname(full_path)
        owned_by = if parent_path != full_path do
          make_relative(root_path, parent_path)
        else
          nil
        end

        %Node{
          id: node_id,
          class: "file",
          data: build_file_data(full_path, root_path),
          owned_by: owned_by
        }
      {:ok, %File.Stat{type: :directory}} ->
        parent_path = Path.dirname(full_path)
        owned_by = if parent_path != full_path do
          make_relative(root_path, parent_path)
        else
          nil
        end

        %Node{
          id: node_id,
          class: "folder",
          data: build_folder_data(full_path, root_path),
          owned_by: owned_by
        }
      {:error, _} -> nil
    end
  end

  @impl true
  def get_all_nodes_of_class(fs_graph, class_id) when is_binary(class_id) do
    get_all_nodes_of_class(fs_graph, [class_id])
  end

  @impl true
  def get_all_nodes_of_class(%{root: root_path}, class_ids) when is_list(class_ids) do
    all_paths = collect_all_paths(root_path)

    Enum.filter(all_paths, fn path ->
      full_path = resolve_path(root_path, path)
      node_class = get_node_class(full_path)
      node_class in class_ids or inherits_from_class?(node_class, class_ids)
    end)
  end


  @impl true
  def insert_node(%{root: root_path} = fs_graph, %Node{id: node_id, class: class_id, data: node_data}) do
    full_path = resolve_path(root_path, node_id)

    case class_id do
      "file" ->
        contents = Map.get(node_data, "contents", "")
        File.write(full_path, contents)
      "folder" ->
        File.mkdir_p(full_path)
      _ ->
        {:error, "Unsupported class: #{class_id}"}
    end

    # Return the unchanged graph since filesystem operations are side effects
    fs_graph
  end

  @impl true
  def insert_nodes(fs_graph, nodes) when is_list(nodes) do
    Enum.reduce(nodes, fs_graph, fn node, acc ->
      insert_node(acc, node)
    end)
  end

  @impl true
  def get_node_data(%{root: root_path}, node_id, property_name, default \\ nil) do
    full_path = resolve_path(root_path, node_id)

    case File.stat(full_path) do
      {:ok, %File.Stat{type: type}} ->
        data = case type do
          :regular -> build_file_data(full_path, root_path)
          :directory -> build_folder_data(full_path, root_path)
        end
        Map.get(data, property_name, default)
      {:error, _} -> default
    end
  end

  @impl true
  def follow_reference(%{root: root_path} = fs_graph, node_id, reference_property) do
    full_path = resolve_path(root_path, node_id)

    case reference_property do
      "parent" ->
        parent_path = Path.dirname(full_path)
        if parent_path != full_path do
          get_node(fs_graph, make_relative(root_path, parent_path))
        else
          nil
        end
      "children" ->
        case File.ls(full_path) do
          {:ok, children} ->
            Enum.map(children, fn child ->
              child_path = Path.join(full_path, child)
              get_node(fs_graph, make_relative(root_path, child_path))
            end)
            |> Enum.reject(&is_nil/1)
          {:error, _} -> []
        end
      _ -> nil
    end
  end

  # Private helper functions (same as before)

  defp collect_all_paths(root_path) do
    case File.stat(root_path) do
      {:ok, %File.Stat{type: :directory}} ->
        walk_directory(root_path, root_path)
      {:ok, %File.Stat{type: :regular}} ->
        ["/"]
      {:error, _} ->
        []
    end
  end

  defp walk_directory(current_path, root_path) do
    relative_path = make_relative(root_path, current_path)

    case File.ls(current_path) do
      {:ok, entries} ->
        child_paths = Enum.flat_map(entries, fn entry ->
          entry_path = Path.join(current_path, entry)
          case File.stat(entry_path) do
            {:ok, %File.Stat{type: :directory}} ->
              walk_directory(entry_path, root_path)
            {:ok, %File.Stat{type: :regular}} ->
              [make_relative(root_path, entry_path)]
            _ -> []
          end
        end)
        [relative_path | child_paths]
      {:error, _} ->
        [relative_path]
    end
  end

  defp resolve_path(root_path, node_id) do
    case node_id do
      "/" -> root_path
      path -> Path.join(root_path, String.trim_leading(path, "/"))
    end
  end

  defp make_relative(root_path, full_path) do
    case Path.relative_to(full_path, root_path) do
      ^full_path -> "/"  # Path is not relative to root
      relative -> "/" <> relative
    end
  end

  defp build_file_data(full_path, root_path) do
    contents = case File.read(full_path) do
      {:ok, data} -> data
      {:error, _} -> ""
    end

    parent_path = Path.dirname(full_path)
    parent_ref = if parent_path != full_path do
      %Node.Ref{id: make_relative(root_path, parent_path), composite: false}
    else
      nil
    end

    %{
      "name" => Path.basename(full_path),
      "contents" => contents,
      "extension" => Path.extname(full_path),
      "parent" => parent_ref
    }
  end

  defp build_folder_data(full_path, root_path) do
    children_refs = case File.ls(full_path) do
      {:ok, entries} ->
        Enum.map(entries, fn entry ->
          child_path = Path.join(full_path, entry)
          %Node.Ref{id: make_relative(root_path, child_path), composite: true}
        end)
      {:error, _} -> []
    end

    parent_path = Path.dirname(full_path)
    parent_ref = if parent_path != full_path do
      %Node.Ref{id: make_relative(root_path, parent_path), composite: true}
    else
      nil
    end

    %{
      "name" => Path.basename(full_path),
      "children" => children_refs,
      "parent" => parent_ref
    }
  end

  defp get_node_class(full_path) do
    case File.stat(full_path) do
      {:ok, %File.Stat{type: :regular}} -> "file"
      {:ok, %File.Stat{type: :directory}} -> "folder"
      _ -> nil
    end
  end

  defp inherits_from_class?(node_class, target_classes) do
    # Both file and folder inherit from node
    case node_class do
      "file" -> "node" in target_classes
      "folder" -> "node" in target_classes
      _ -> false
    end
  end
end
