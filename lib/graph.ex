defmodule Paradigm.Graph do
  @moduledoc """
  Defines the behaviour for Graph implementations. This decouples operations (conformance, abstraction, transforms) from the underlying graph storage.
  """

  @type graph :: term()
  @type node_id :: Paradigm.id()
  @type class_id :: Paradigm.id()

  @callback new() :: graph
  @callback get_all_nodes(graph) :: [node_id]
  @callback get_all_classes(graph) :: [class_id]
  @callback get_node(graph, node_id) :: Node.t() | nil
  @callback get_all_nodes_of_class(graph, class_id | [class_id]) :: [node_id]
  @callback insert_node(graph, node_id, class_id, map()) :: graph
  @callback insert_nodes(graph, map() | list()) :: graph
  @callback get_node_data(graph, node_id, any(), any()) :: any()
  @callback follow_reference(graph, node_id, any()) :: Node.t() | nil
end
