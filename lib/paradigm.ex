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
    |> Enum.map(fn id -> {id, Paradigm.Graph.get_node(graph, id)} end)
    |> Map.new()
  end

  def indexed_by_ref(node_map, attr) do
    node_map
    |> Enum.group_by(
      fn {_id, node} ->
        node.data[attr].id
      end,
      fn {_id, node} ->
        node
      end
    )
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
