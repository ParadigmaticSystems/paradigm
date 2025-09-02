defmodule Paradigm.Transform.Identity do
  @moduledoc """
  The trivial transform.
  """
  @behaviour Paradigm.Transform

  @impl true
  def transform(source_graph, target_graph, _opts) do
    source_graph
    |> Paradigm.Graph.get_all_nodes()
    |> Enum.reduce({:ok, target_graph}, fn node_id, {:ok, acc} ->
      case Paradigm.Graph.get_node(source_graph, node_id) do
        nil -> {:error, "Node #{node_id} not found"}
        node -> {:ok, Paradigm.Graph.insert_node(acc, node)}
      end
    end)
  end
end
