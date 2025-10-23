defmodule Paradigm do
  @moduledoc """
  The top-level `Paradigm` data model object.
  """

  alias Paradigm.{PrimitiveType, Package, Class, Property, Enumeration}

  @type id :: String.t()
  @type name :: String.t()

  @type t :: %__MODULE__{
          name: name(),
          description: String.t(),
          primitive_types: %{id() => PrimitiveType.t()},
          packages: %{id() => Package.t()},
          classes: %{id() => Class.t()},
          properties: %{id() => Property.t()},
          enumerations: %{id() => Enumeration.t()}
        }

  defstruct name: "",
            description: "",
            primitive_types: %{},
            packages: %{},
            classes: %{},
            properties: %{},
            enumerations: %{}

  def get_all_attributes(class, paradigm) do
    case class do
      nil ->
        []

      %__MODULE__.Class{} = class ->
        direct = class.owned_attributes || []

        inherited =
          (class.super_classes || [])
          |> Enum.flat_map(fn super_id ->
            case paradigm.classes[super_id] do
              nil -> []
              super_class -> get_all_attributes(super_class, paradigm)
            end
          end)

        direct ++ inherited
    end
  end

  def is_subclass_of?(source_class_id, target_class_id, paradigm) do
    case paradigm.classes[source_class_id] do
      nil ->
        false

      source_class ->
        super_classes = source_class.super_classes || []

        target_class_id in super_classes ||
          super_classes
          |> Enum.any?(fn super_id -> is_subclass_of?(super_id, target_class_id, paradigm) end)
    end
  end

  def nodes_of_type(graph, type) do
    Paradigm.Graph.get_all_nodes_of_class(graph, type)
    |> Enum.map(fn id -> Paradigm.Graph.get_node(graph, id) end)
  end

  @doc """
  Indexes 1-to-many associations.
  (Each Graph instance has a unique paradigm)
  """
  def parent_lookup_table(nodes, attr) do
    nodes
    |> Enum.map(fn node ->
      {node.data[attr].id, node}
    end)
    |> Enum.reduce(%{}, fn {k, v}, acc ->
      case Map.has_key?(acc, k) do
        true -> raise "Failed to make lookup table. Duplicate key: #{inspect(k)}"
        false -> Map.put(acc, k, v)
      end
    end)
  end


  def parent_node_lookup_table(graph, association_type, parent_key, child_key) do
    associations = nodes_of_type(graph, association_type)
    |> Enum.reduce(%{}, fn ass_node, acc ->

    end)
  end


  def child_node_lookup_table(graph, association_type, parent_key, child_key) do
    associations = nodes_of_type(graph, association_type)
    |> Enum.reduce(%{}, fn ass_node, acc ->
      with parent_data when not is_nil(parent_data) <- ass_node.data[parent_key],
           child_data when not is_nil(child_data) <- ass_node.data[child_key] do
        parent_id = parent_data.id
        child_id = child_data.id
        child_node = Paradigm.Graph.get_node(graph, child_id)
        Map.update(acc, parent_id, [child_node], fn existing -> existing ++ [child_node] end)
      else
        _ -> acc
      end
    end)
  end

  @doc """
  Turns association nodes into tuples with dereferenced nodes sorted by dependence
  """
  def topological_join(graph, association_type, parent_ref, child_ref) do
    digraph = :digraph.new()
    associations = nodes_of_type(graph, association_type)
    lookup_by_instance = parent_lookup_table(associations, "instance")

    associations
    |> Enum.each(fn ass_node ->
      parent_id = ass_node.data[parent_ref].id
      child_id = ass_node.data[child_ref].id

      :digraph.add_vertex(digraph, parent_id)
      :digraph.add_vertex(digraph, child_id)
      :digraph.add_edge(digraph, child_id, parent_id)
    end)

    sorted_ids =
      :digraph_utils.topsort(digraph)
      |> Enum.reverse()

    :digraph.delete(digraph)

    sorted_ids
    |> Enum.map(fn id ->
      ass_node = lookup_by_instance[id]

      {ass_node, Paradigm.Graph.get_node(graph, ass_node.data[child_ref].id),
       Paradigm.Graph.get_node(graph, ass_node.data[parent_ref].id)}
    end)
  end

  def transform(transformer, source) do
    target = Paradigm.Graph.MapGraph.new()
    Paradigm.Transform.transform(transformer, source, target)
  end

  def transform!(transformer, source) do
    {:ok, result} = transform(transformer, source)
    result
  end
end
