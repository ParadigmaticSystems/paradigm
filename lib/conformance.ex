defmodule Paradigm.Conformance do
  alias Paradigm.Graph.Node.Ref

  defmodule Issue do
    defstruct [:kind, :node_id, :property, :details]

    @type t :: %__MODULE__{
            kind:
              :invalid_class
              | :unknown_property
              | :missing_property
              | :cardinality_too_low
              | :cardinality_too_high
              | :should_be_list
              | :references_missing_node
              | :references_wrong_class
              | :invalid_enum_value
              | :expected_reference,
            node_id: Paradigm.id(),
            property: String.t() | nil,
            details: map() | nil
          }
  end

  defmodule Result do
    defstruct [:issues]

    @type t :: %__MODULE__{
            issues: [Issue.t()]
          }

    def valid?(%Result{issues: []}), do: true
    def valid?(%Result{}), do: false
  end

  @spec check_graph(%Paradigm{}, any()) :: Result.t()
  def check_graph(%Paradigm{} = paradigm, graph) do
    issues =
      Paradigm.Graph.get_all_nodes(graph)
      |> Enum.flat_map(&validate_node(&1, paradigm, graph))

    %Result{issues: issues}
  end

  defp validate_node(node_id, paradigm, graph) do
    with {:ok, node} <- get_node_safe(graph, node_id),
         {:ok, _class} <- get_class_safe(paradigm, node.class) do
      validate_node_properties(node, node_id, paradigm, graph)
    else
      {:error, :invalid_class} ->
        class = get_node_class(graph, node_id)
        [%Issue{kind: :invalid_class, node_id: node_id, property: nil, details: %{class: class}}]

      {:error, :node_not_found} ->
        []
    end
  end

  defp validate_node_properties(node, node_id, paradigm, graph) do
    class = paradigm.classes[node.class]
    attributes = Paradigm.get_all_attributes(class, paradigm)
    properties = Enum.map(attributes, &paradigm.properties[&1])

    [
      validate_property_coverage(node, node_id, properties),
      validate_property_values(node, node_id, properties, paradigm, graph)
    ]
    |> List.flatten()
  end

  defp validate_property_coverage(node, node_id, properties) do
    data_keys = MapSet.new(Map.keys(node.data))
    property_names = MapSet.new(Enum.map(properties, & &1.name))

    required_names =
      MapSet.new(Enum.filter(properties, &(&1.lower_bound > 0)) |> Enum.map(& &1.name))

    missing_issues =
      MapSet.difference(required_names, data_keys)
      |> Enum.map(&%Issue{kind: :missing_property, node_id: node_id, property: &1, details: nil})

    unknown_issues =
      MapSet.difference(data_keys, property_names)
      |> Enum.map(&%Issue{kind: :unknown_property, node_id: node_id, property: &1, details: nil})

    missing_issues ++ unknown_issues
  end

  defp validate_property_values(node, node_id, properties, paradigm, graph) do
    Enum.flat_map(properties, fn property ->
      value = Map.get(node.data, property.name)

      # Only validate if the property is present
      if Map.has_key?(node.data, property.name) do
        validate_property_value(node_id, property, value, paradigm, graph)
      else
        []
      end
    end)
  end

  defp validate_property_value(node_id, property, value, paradigm, graph) do
    [
      validate_cardinality(node_id, property, value),
      validate_references(node_id, property, value, paradigm, graph),
      validate_enum_value(node_id, property, value, paradigm)
    ]
    |> List.flatten()
  end

  defp validate_cardinality(node_id, property, value) do
    count = get_count(value)
    is_list = is_list(value)

    cond do
      count < property.lower_bound ->
        [
          %Issue{
            kind: :cardinality_too_low,
            node_id: node_id,
            property: property.name,
            details: %{count: count, minimum: property.lower_bound}
          }
        ]

      property.upper_bound != :infinity and count > property.upper_bound ->
        [
          %Issue{
            kind: :cardinality_too_high,
            node_id: node_id,
            property: property.name,
            details: %{count: count, maximum: property.upper_bound}
          }
        ]

      not is_list and property.upper_bound > 1 ->
        [
          %Issue{
            kind: :should_be_list,
            node_id: node_id,
            property: property.name,
            details: nil
          }
        ]

      true ->
        []
    end
  end

  defp validate_references(node_id, property, value, paradigm, graph) do
    if is_reference_property?(property, paradigm) do
      issues_from_refs =
        value
        |> extract_refs()
        |> Enum.flat_map(&validate_single_reference(node_id, property, &1, paradigm, graph))

      issues_from_non_refs = validate_non_reference_values(node_id, property, value, paradigm)

      issues_from_refs ++ issues_from_non_refs
    else
      []
    end
  end

  defp validate_non_reference_values(node_id, property, value, paradigm) do
    if is_reference_property?(property, paradigm) do
      non_ref_values = extract_non_refs(value)

      Enum.map(non_ref_values, fn non_ref_value ->
        %Issue{
          kind: :expected_reference,
          node_id: node_id,
          property: property.name,
          details: %{actual_type: get_type_name(non_ref_value)}
        }
      end)
    else
      []
    end
  end

  defp validate_single_reference(node_id, property, %Ref{id: referenced_id}, paradigm, graph) do
    case get_node_safe(graph, referenced_id) do
      {:error, :node_not_found} ->
        [
          %Issue{
            kind: :references_missing_node,
            node_id: node_id,
            property: property.name,
            details: %{referenced_id: referenced_id}
          }
        ]

      {:ok, referenced_node} ->
        if valid_class_reference?(referenced_node.class, property.type, paradigm) do
          []
        else
          [
            %Issue{
              kind: :references_wrong_class,
              node_id: node_id,
              property: property.name,
              details: %{class: referenced_node.class}
            }
          ]
        end
    end
  end

  defp validate_enum_value(node_id, property, value, paradigm) do
    if is_enum_property?(property, paradigm) do
      enum = paradigm.enumerations[property.type]

      value
      |> normalize_to_list()
      |> Enum.reject(&is_nil/1)
      |> Enum.reject(&(&1 in enum.literals))
      |> Enum.map(
        &%Issue{
          kind: :invalid_enum_value,
          node_id: node_id,
          property: property.name,
          details: %{value: &1}
        }
      )
    else
      []
    end
  end

  # Helper functions
  defp get_node_safe(graph, node_id) do
    case Paradigm.Graph.get_node(graph, node_id) do
      nil -> {:error, :node_not_found}
      node -> {:ok, node}
    end
  end

  defp get_node_class(graph, node_id) do
    case Paradigm.Graph.get_node(graph, node_id) do
      nil -> nil
      node -> node.class
    end
  end

  defp get_class_safe(paradigm, class_name) do
    case Map.fetch(paradigm.classes, class_name) do
      {:ok, class} -> {:ok, class}
      :error -> {:error, :invalid_class}
    end
  end

  defp normalize_to_list(value) when is_list(value), do: value
  defp normalize_to_list(nil), do: []
  defp normalize_to_list(value), do: [value]

  defp extract_refs(value) when is_list(value) do
    Enum.filter(value, &match?(%Ref{}, &1))
  end

  defp extract_refs(%Ref{} = ref), do: [ref]
  defp extract_refs(_), do: []

  defp extract_non_refs(value) when is_list(value) do
    Enum.reject(value, &(match?(%Ref{}, &1) or is_nil(&1)))
  end

  defp extract_non_refs(%Ref{}), do: []
  defp extract_non_refs(nil), do: []
  defp extract_non_refs(value), do: [value]

  defp get_type_name(value) when is_binary(value), do: "string"
  defp get_type_name(value) when is_integer(value), do: "integer"
  defp get_type_name(value) when is_float(value), do: "float"
  defp get_type_name(value) when is_boolean(value), do: "boolean"
  defp get_type_name(value) when is_list(value), do: "list"
  defp get_type_name(value) when is_map(value), do: "map"
  defp get_type_name(_), do: "unknown"

  defp get_count(value) when is_list(value), do: length(value)
  defp get_count(nil), do: 0
  defp get_count(_), do: 1

  defp is_reference_property?(property, paradigm) do
    not (property.type in Map.keys(paradigm.primitive_types) or
           property.type in Map.keys(paradigm.enumerations))
  end

  defp is_enum_property?(property, paradigm) do
    Map.has_key?(paradigm.enumerations, property.type)
  end

  defp valid_class_reference?(actual_class, expected_type, paradigm) do
    actual_class == expected_type or
      Paradigm.is_subclass_of?(actual_class, expected_type, paradigm)
  end
end
