defmodule Paradigm.Graph.MapImpl do
  @moduledoc """
  A map-based implementation of the Graph behaviour for handling in-memory data.
  """

  @behaviour Paradigm.Graph

  alias Paradigm.Graph.Node

  @type t :: %{Paradigm.id() => Node.t()}

  @impl true
  def new(), do: %{}

  @impl true
  def get_all_nodes(graph) do
    Map.keys(graph)
  end

  @impl true
  def get_all_classes(graph) do
    graph
    |> Map.values()
    |> Enum.map(& &1.class)
    |> Enum.uniq()
  end

  @impl true
  def get_node(graph, node_id) do
    graph[node_id]
  end

  @impl true
  def insert_node(graph, node_id, class, data \\ %{}) do
    Map.put(graph, node_id, %Node{class: class, data: data})
  end

  @impl true
  def insert_nodes(graph, nodes) when is_map(nodes) do
    Map.merge(graph, nodes)
  end

  @impl true
  def insert_nodes(graph, nodes) when is_list(nodes) do
    Enum.reduce(nodes, graph, fn {id, node}, acc ->
      Map.put(acc, id, node)
    end)
  end

  @impl true
  def get_all_nodes_of_class(graph, class_ids) when is_list(class_ids) do
    graph
    |> Enum.filter(fn {_id, node} -> node.class in class_ids end)
    |> Enum.map(fn {id, _node} -> id end)
  end

  @impl true
  def get_all_nodes_of_class(graph, class_id) do
    get_all_nodes_of_class(graph, [class_id])
  end

  @impl true
  def get_node_data(graph, node_id, key, default \\ nil) do
    case graph[node_id] do
      %Node{data: data} -> Map.get(data, key, default)
      nil -> default
    end
  end

  @impl true
  def follow_reference(graph, node_id, reference_key) do
    case get_node_data(graph, node_id, reference_key) do
      nil -> nil
      ref_id -> graph[ref_id]
    end
  end
end
