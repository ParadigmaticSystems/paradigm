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
  def get_name(%{metadata: metadata}) do
    Keyword.get(metadata, :name)
  end

  @impl true
  def get_description(%{metadata: metadata}) do
    Keyword.get(metadata, :description)
  end

  @impl true
  def get_content_hash(%{nodes: graph}) do
    Base.encode16(:crypto.hash(:sha256, :erlang.term_to_binary(graph)))
    |> String.slice(-5..-1)
  end

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
  def stream_all_nodes(%{nodes: graph}) do
    Stream.map(graph, fn {_id, node} -> node end)
  end

  @impl true
  def insert_node(%{nodes: graph} = map_graph, %Node{id: id, data: data} = node) do
    normalized_data = normalize_keys_to_strings(data)
    normalized_node = %{node | data: normalized_data}
    new_graph = Map.put(graph, id, normalized_node)
    %{map_graph | nodes: new_graph}
  end

  @impl true
  def insert_nodes(%{nodes: graph} = map_graph, nodes) when is_list(nodes) do
    new_graph =
      Enum.reduce(nodes, graph, fn %Node{id: id, data: data} = node, acc ->
        normalized_data = normalize_keys_to_strings(data)
        normalized_node = %{node | data: normalized_data}
        Map.put(acc, id, normalized_node)
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
  def follow_reference(%{nodes: graph}, node_id, reference_key) do
    case graph[node_id] do
      nil ->
        nil

      node ->
        case Map.get(node.data, reference_key) do
          %Node.Ref{id: ref_id} -> graph[ref_id]
          _ -> nil
        end
    end
  end

  defp normalize_keys_to_strings(data) when is_map(data) do
    data
    |> Enum.map(fn {key, value} -> {to_string(key), value} end)
    |> Map.new()
  end
end
