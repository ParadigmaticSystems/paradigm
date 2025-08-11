defmodule Paradigm.Graph.MapGraph do
  defstruct [:nodes, :metadata]

  def new(opts \\ []) do
    %__MODULE__{
      nodes: %{},
      metadata: Keyword.take(opts, [:name, :description])
    }
  end
end

defimpl Paradigm.Graph, for: Paradigm.Graph.MapGraph do
  alias Paradigm.Graph.Node

  @impl true
  def get_all_nodes(%{nodes: graph}) do
    Map.keys(graph)
  end

  @impl true
  def get_all_classes(%{nodes: graph}) do
    graph
    |> Map.values()
    |> Enum.map(& &1.class)
    |> Enum.uniq()
  end

  @impl true
  def get_node(%{nodes: graph}, node_id) do
    graph[node_id]
  end

  @impl true
  def insert_node(%{nodes: graph} = map_graph, node_id, class, data \\ %{}) do
    normalized_data = normalize_keys_to_strings(data)
    new_graph = Map.put(graph, node_id, %Node{class: class, data: normalized_data})
    %{map_graph | nodes: new_graph}
  end

  @impl true
  def insert_nodes(%{nodes: graph} = map_graph, nodes) when is_map(nodes) do
    normalized_nodes =
      nodes
      |> Enum.map(fn {id, %Node{class: class, data: data}} ->
        {id, %Node{class: class, data: normalize_keys_to_strings(data)}}
      end)
      |> Map.new()

    new_graph = Map.merge(graph, normalized_nodes)
    %{map_graph | nodes: new_graph}
  end

  @impl true
  def insert_nodes(%{nodes: graph} = map_graph, nodes) when is_list(nodes) do
    new_graph = Enum.reduce(nodes, graph, fn {id, %Node{class: class, data: data}}, acc ->
      normalized_data = normalize_keys_to_strings(data)
      Map.put(acc, id, %Node{class: class, data: normalized_data})
    end)
    %{map_graph | nodes: new_graph}
  end

  @impl true
  def get_all_nodes_of_class(%{nodes: graph}, class_ids) when is_list(class_ids) do
    graph
    |> Enum.filter(fn {_id, node} -> node.class in class_ids end)
    |> Enum.map(fn {id, _node} -> id end)
  end

  @impl true
  def get_all_nodes_of_class(map_graph, class_id) do
    get_all_nodes_of_class(map_graph, [class_id])
  end

  @impl true
  def get_node_data(%{nodes: graph}, node_id, key, default \\ nil) do
    case graph[node_id] do
      %Node{data: data} -> Map.get(data, key, default)
      nil -> default
    end
  end

  @impl true
  def follow_reference(%{nodes: graph} = map_graph, node_id, reference_key) do
    case get_node_data(map_graph, node_id, reference_key) do
      nil -> nil
      ref_id -> graph[ref_id]
    end
  end

  defp normalize_keys_to_strings(data) when is_map(data) do
    data
    |> Enum.map(fn {key, value} -> {to_string(key), value} end)
    |> Map.new()
  end
end
