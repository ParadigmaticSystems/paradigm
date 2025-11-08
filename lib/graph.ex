defprotocol Paradigm.Graph do
  @moduledoc """
  Defines the protocol for Graph implementations. This decouples operations (conformance, abstraction, transforms) from the underlying graph storage.
  """

  @type node_id :: Paradigm.id()
  @type class_id :: Paradigm.id()

  @spec get_name(t()) :: String.t() | nil
  def get_name(graph)

  @spec get_description(t()) :: String.t() | nil
  def get_description(graph)

  @spec get_content_hash(t()) :: String.t() | nil
  def get_content_hash(graph)

  @spec get_all_nodes(t()) :: [node_id]
  def get_all_nodes(graph)

  @spec stream_all_nodes(t()) :: Enumerable.t(Node.t())
  def stream_all_nodes(graph)

  @spec get_all_classes(t()) :: [class_id]
  def get_all_classes(graph)

  @spec get_node(t(), node_id) :: Node.t() | nil
  def get_node(graph, node_id)

  @spec get_all_nodes_of_class(t(), class_id | [class_id]) :: [node_id]
  def get_all_nodes_of_class(graph, class_id)

  @spec insert_node(t(), Paradigm.Graph.Node.t()) :: t()
  def insert_node(graph, node)

  @spec insert_nodes(t(), [Paradigm.Graph.Node.t()]) :: t()
  def insert_nodes(graph, nodes)

  @spec follow_reference(t(), node_id, any()) :: Node.t() | nil
  def follow_reference(graph, node_id, reference)
end
