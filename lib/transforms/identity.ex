defmodule Paradigm.Transform.Identity do
  @moduledoc """
  The trivial transform.
  """
  @behaviour Paradigm.Transform
  alias Paradigm.Graph.Instance

  @impl true
  def transform(
        %Instance{impl: source_impl, data: source_data, name: name, description: description},
        target_impl,
        _opts
      ) do
    target_graph = target_impl.new()

    nodes = source_impl.get_all_nodes(source_data)

    transformed_graph =
      Enum.reduce(nodes, target_graph, fn node_id, acc_graph ->
        case source_impl.get_node(source_data, node_id) do
          nil ->
            acc_graph

          node ->
            target_impl.insert_node(
              acc_graph,
              node_id,
              node.class,
              node.data
            )
        end
      end)

    {:ok, Instance.new(target_impl, transformed_graph, name, description)}
  end
end
