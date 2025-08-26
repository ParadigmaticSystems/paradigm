defmodule Paradigm.Graph.Canonical do
  @moduledoc """
  Converts graph nodes into canonical Elixir structs with expanded references.
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
      nil -> nil
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
