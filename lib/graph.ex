defprotocol Paradigm.Graph do
  @moduledoc """
  Defines the behaviour for Graph implementations. This decouples operations (conformance, abstraction, transforms) from the underlying graph storage.
  Think of "data" as "all the information that the implementation requires to complete the operation". It might be the graph itself, or a pointer to an external source.
  """

  @type node_id :: Paradigm.id()
  @type class_id :: Paradigm.id()

  @spec get_all_nodes(t()) :: [node_id]
  def get_all_nodes(data)

  @spec stream_all_nodes(t()) :: Enumerable.t(Node.t())
  def stream_all_nodes(data)

  @spec get_all_classes(t()) :: [class_id]
  def get_all_classes(data)

  @spec get_node(t(), node_id) :: Node.t() | nil
  def get_node(data, node_id)

  @spec get_all_nodes_of_class(t(), class_id | [class_id]) :: [node_id]
  def get_all_nodes_of_class(data, class_id)

  @spec insert_node(t(), Paradigm.Graph.Node.t()) :: t()
  def insert_node(data, node)

  @spec insert_nodes(t(), [Paradigm.Graph.Node.t()]) :: t()
  def insert_nodes(data, nodes)

  @spec get_node_data(t(), node_id, any()) :: {:ok, any()} | :error
  def get_node_data(data, node_id, key)

  @spec get_node_data(t(), node_id, any(), any()) :: any()
  def get_node_data(data, node_id, key, default)

  @spec follow_reference(t(), node_id, any()) :: Node.t() | nil
  def follow_reference(data, node_id, reference)
end
