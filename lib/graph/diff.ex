defmodule Paradigm.Graph.Diff do
  alias Paradigm.Graph
  @doc """
  Computes the difference between two graphs, capturing missing nodes, added nodes, and changed attributes.

  Returns a map with:
  - `:added` - list of node_ids present in `new_graph` but not in `old_graph`
  - `:removed` - list of node_ids present in `old_graph` but not in `new_graph`
  - `:changed` - map of node_id => %{class: %{old: class, new: class}, data: %{key => %{old: value, new: value}}} for nodes with different attributes or class
  """
  @spec diff(Graph.t(), Graph.t()) :: %{
    added: [Graph.node_id()],
    removed: [Graph.node_id()],
    changed: %{Graph.node_id() => map()}
  }
  def diff(old_graph, new_graph) do
    old_nodes = Graph.get_all_nodes(old_graph) |> MapSet.new()
    new_nodes = Graph.get_all_nodes(new_graph) |> MapSet.new()

    added = MapSet.difference(new_nodes, old_nodes) |> MapSet.to_list()
    removed = MapSet.difference(old_nodes, new_nodes) |> MapSet.to_list()

    common_nodes = MapSet.intersection(old_nodes, new_nodes)

    changed = common_nodes
      |> Enum.reduce(%{}, fn node_id, acc ->
        old_node = Graph.get_node(old_graph, node_id)
        new_node = Graph.get_node(new_graph, node_id)

        if old_node != new_node do
          node_diff = compute_node_diff(old_node, new_node)
          Map.put(acc, node_id, node_diff)
        else
          acc
        end
      end)

    %{
      added: added,
      removed: removed,
      changed: changed
    }
  end

  defp compute_node_diff(old_node, new_node) do
    diff = %{}

    diff = if old_node.class != new_node.class do
      Map.put(diff, :class, %{old: old_node.class, new: new_node.class})
    else
      diff
    end

    old_data = old_node.data || %{}
    new_data = new_node.data || %{}

    all_keys = MapSet.union(MapSet.new(Map.keys(old_data)), MapSet.new(Map.keys(new_data)))

    data_changes = all_keys
      |> Enum.reduce(%{}, fn key, acc ->
        old_value = Map.get(old_data, key)
        new_value = Map.get(new_data, key)

        if old_value != new_value do
          Map.put(acc, key, %{old: old_value, new: new_value})
        else
          acc
        end
      end)

    if data_changes != %{} do
      Map.put(diff, :data, data_changes)
    else
      diff
    end
  end

  @doc """
  Asserts that two graphs are equal by computing their diff and throwing an error if there are any differences.

  Raises an error if the graphs differ, otherwise returns :ok.
  """
  @spec assert_equal(Graph.t(), Graph.t()) :: :ok
  def assert_equal(old_graph, new_graph) do
    differences = diff(old_graph, new_graph)

    if differences.added == [] and differences.removed == [] and differences.changed == %{} do
      :ok
    else
      error_message = format_differences(differences)
      raise "Graphs are not equal.\n#{error_message}"
    end
  end

  defp format_differences(differences) do
    parts = []

    parts = if differences.added != [] do
      added_section = "Added nodes:\n" <>
        Enum.map_join(differences.added, "\n", fn node_id -> "  - #{node_id}" end)
      [added_section | parts]
    else
      parts
    end

    parts = if differences.removed != [] do
      removed_section = "Removed nodes:\n" <>
        Enum.map_join(differences.removed, "\n", fn node_id -> "  - #{node_id}" end)
      [removed_section | parts]
    else
      parts
    end

    parts = if differences.changed != %{} do
      changed_section = "Changed nodes:\n" <>
        Enum.map_join(differences.changed, "\n", fn {node_id, changes} ->
          node_changes = format_node_changes(changes)
          "  - #{node_id}:\n#{node_changes}"
        end)
      [changed_section | parts]
    else
      parts
    end

    Enum.reverse(parts) |> Enum.join("\n\n")
  end

  defp format_node_changes(changes) do
    parts = []

    parts = if Map.has_key?(changes, :class) do
      class_change = changes.class
      class_section = "    class: #{inspect(class_change.old)} → #{inspect(class_change.new)}"
      [class_section | parts]
    else
      parts
    end

    parts = if Map.has_key?(changes, :data) do
      data_changes = changes.data
      data_section = Enum.map_join(data_changes, "\n", fn {key, %{old: old_val, new: new_val}} ->
        "    #{key}: #{inspect(old_val)} → #{inspect(new_val)}"
      end)
      [data_section | parts]
    else
      parts
    end

    Enum.reverse(parts) |> Enum.join("\n")
  end

end
