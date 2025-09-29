defmodule Paradigm.Graph.Canonical do
  @moduledoc """
  Converts graphs into canonical Elixir structs, and vice versa.
  """

  alias Paradigm.Graph.Node

  @doc """
  Converts a graph node into its canonical Elixir struct representation.

  - The struct name is derived from the node's class
  - All `%Paradigm.Graph.Node.Ref{}` values are expanded in place
  - Cycle detection prevents infinite recursion
  """
  @spec to_struct(Paradigm.Graph.t(), Paradigm.Graph.node_id()) :: struct() | nil
  def to_struct(graph, node_id) do
    to_struct(graph, node_id, MapSet.new())
  end

  @spec to_struct(Paradigm.Graph.t(), Paradigm.Graph.node_id(), MapSet.t()) :: struct() | nil
  defp to_struct(graph, node_id, visited) do
    case Paradigm.Graph.get_node(graph, node_id) do
      nil ->
        nil

      node ->
        if MapSet.member?(visited, node_id) do
          # Return a cycle marker or the node_id to indicate a cycle
          %{__cycle_ref__: node_id}
        else
          new_visited = MapSet.put(visited, node_id)
          build_struct(graph, node, new_visited)
        end
    end
  end

  @doc """
  Converts an Elixir struct into graph nodes using the Graph protocol.

  - Uses the struct's module name as the class_id
  - Converts nested structs into references
  - Inserts all nodes into the graph
  """
  @spec struct_to_graph(Paradigm.Graph.t(), struct(), Paradigm.Graph.node_id()) ::
          Paradigm.Graph.t()
  def struct_to_graph(graph, struct_data, node_id) do
    struct_to_graph(graph, struct_data, node_id, MapSet.new())
  end

  @spec struct_to_graph(Paradigm.Graph.t(), struct(), Paradigm.Graph.node_id(), MapSet.t()) ::
          Paradigm.Graph.t()
  defp struct_to_graph(graph, struct_data, node_id, visited) do
    if MapSet.member?(visited, node_id) do
      graph
    else
      new_visited = MapSet.put(visited, node_id)

      class_id = struct_data.__struct__
      {converted_data, updated_graph} = convert_struct_data(graph, struct_data, new_visited)

      node = %Node{
        id: node_id,
        class: class_id,
        data: converted_data
      }

      Paradigm.Graph.insert_node(updated_graph, node)
    end
  end

  defp convert_struct_data(graph, struct_data, visited) do
    struct_map = Map.from_struct(struct_data)

    Enum.reduce(struct_map, {%{}, graph}, fn {key, value}, {acc_data, acc_graph} ->
      {converted_value, updated_graph} = convert_value(acc_graph, value, visited)
      {Map.put(acc_data, key, converted_value), updated_graph}
    end)
  end

  defp convert_value(graph, value, visited) when is_struct(value) do
    # Generate a unique node_id for nested structs
    nested_node_id = generate_node_id(value)
    updated_graph = struct_to_graph(graph, value, nested_node_id, visited)
    {%Node.Ref{id: nested_node_id}, updated_graph}
  end

  defp convert_value(graph, value, visited) when is_list(value) do
    Enum.reduce(value, {[], graph}, fn item, {acc_list, acc_graph} ->
      {converted_item, updated_graph} = convert_value(acc_graph, item, visited)
      {[converted_item | acc_list], updated_graph}
    end)
    |> then(fn {list, graph} -> {Enum.reverse(list), graph} end)
  end

  defp convert_value(graph, value, visited) when is_map(value) do
    Enum.reduce(value, {%{}, graph}, fn {k, v}, {acc_map, acc_graph} ->
      {converted_value, updated_graph} = convert_value(acc_graph, v, visited)
      {Map.put(acc_map, k, converted_value), updated_graph}
    end)
  end

  defp convert_value(graph, value, _visited) do
    # Primitive values pass through unchanged
    {value, graph}
  end

  defp generate_node_id(struct_data) do
    # Simple approach: use module name + hash of struct content
    content_hash = :erlang.phash2(struct_data)
    "#{struct_data.__struct__}_#{content_hash}"
  end

  defp build_struct(graph, %Node{class: class, data: data}, visited) do
    struct_module = Module.concat([class])

    expanded_data = expand_data(graph, data, visited)

    try do
      struct(struct_module, expanded_data)
    rescue
      UndefinedFunctionError ->
        expanded_data
    end
  end

  defp expand_data(graph, data, visited) when is_map(data) do
    Map.new(data, fn {key, value} ->
      {atomize_key(key), expand_value(graph, value, visited)}
    end)
  end

  defp expand_value(graph, %Node.Ref{id: ref_id}, visited) do
    to_struct(graph, ref_id, visited)
  end

  defp expand_value(graph, value, visited) when is_list(value) do
    Enum.map(value, &expand_value(graph, &1, visited))
  end

  defp expand_value(graph, value, visited) when is_map(value) do
    # Handle nested maps that might contain references
    Map.new(value, fn {k, v} ->
      {atomize_key(k), expand_value(graph, v, visited)}
    end)
  end

  defp expand_value(_graph, value, _visited) do
    # Primitive values pass through unchanged
    value
  end

  defp atomize_key(key) when is_atom(key), do: key
  defp atomize_key(key) when is_binary(key), do: String.to_atom(key)
  defp atomize_key(key), do: String.to_atom("#{key}")
end
