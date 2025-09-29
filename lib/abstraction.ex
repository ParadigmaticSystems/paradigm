defmodule Paradigm.Abstraction do
  @moduledoc """
  Functions for moving between Paradigm structs and corresponding graph data.
  """

  alias Paradigm.Graph.Node
  alias Paradigm.Graph.Node.Ref

  @doc """
  Takes any `Paradigm` and produces the corresponding graph that is invariant against the Metamodel paradigm.
  """
  def embed(paradigm, graph \\ nil) do
    graph =
      graph || Paradigm.Graph.MapGraph.new(name: paradigm.name, description: paradigm.description)

    graph
    |> add_primitive_types(paradigm)
    |> add_packages(paradigm)
    |> add_classes(paradigm)
    |> add_enumerations(paradigm)
    |> add_properties(paradigm)
  end

  defp add_primitive_types(graph, paradigm) do
    Enum.reduce(paradigm.primitive_types, graph, fn {id, primitive_type}, acc ->
      data = %{
        "name" => primitive_type.name
      }

      node = %Node{
        id: id,
        class: "primitive_type",
        data: data
      }

      Paradigm.Graph.insert_node(acc, node)
    end)
  end

  defp add_packages(graph, paradigm) do
    Enum.reduce(paradigm.packages, graph, fn {id, package}, acc ->
      data = %{
        "name" => package.name,
        "uri" => package.uri,
        "nested_packages" =>
          Enum.map(package.nested_packages || [], &%Ref{id: &1, composite: true}),
        "owned_types" => Enum.map(package.owned_types || [], &%Ref{id: &1, composite: true})
      }

      node = %Node{
        id: id,
        class: "package",
        data: data
      }

      Paradigm.Graph.insert_node(acc, node)
    end)
  end

  defp add_classes(graph, paradigm) do
    Enum.reduce(paradigm.classes, graph, fn {id, class}, acc ->
      data = %{
        "name" => class.name,
        "is_abstract" => class.is_abstract,
        "owned_attributes" =>
          Enum.map(class.owned_attributes || [], &%Ref{id: &1, composite: true}),
        "super_classes" => Enum.map(class.super_classes || [], &%Ref{id: &1})
      }

      owner_package_id =
        Enum.find_value(paradigm.packages, fn {package_id, package} ->
          if Enum.member?(package.owned_types || [], id) do
            package_id
          else
            nil
          end
        end)

      node = %Node{
        id: id,
        class: "class",
        data: data,
        owned_by: owner_package_id
      }

      Paradigm.Graph.insert_node(acc, node)
    end)
  end

  defp add_enumerations(graph, paradigm) do
    Enum.reduce(paradigm.enumerations, graph, fn {id, enum}, acc ->
      data = %{
        "name" => enum.name,
        "literals" => enum.literals
      }

      node = %Node{
        id: id,
        class: "enumeration",
        data: data
      }

      Paradigm.Graph.insert_node(acc, node)
    end)
  end

  defp add_properties(graph, paradigm) do
    Enum.reduce(paradigm.properties, graph, fn {id, property}, acc ->
      data = %{
        "name" => property.name,
        "is_ordered" => property.is_ordered,
        "type" =>
          if(property.type,
            do: %Ref{id: property.type, composite: property.is_composite},
            else: nil
          ),
        "is_composite" => property.is_composite,
        "lower_bound" => property.lower_bound,
        "upper_bound" => property.upper_bound,
        "default_value" => property.default_value
      }

      owner_class_id =
        Enum.find_value(paradigm.classes, fn {class_id, class} ->
          if Enum.member?(class.owned_attributes || [], id) do
            class_id
          else
            nil
          end
        end)

      node = %Node{
        id: id,
        class: "property",
        data: data,
        owned_by: owner_class_id
      }

      Paradigm.Graph.insert_node(acc, node)
    end)
  end

  @doc """
  Takes a graph of metamodel type, and returns a top-level `Paradigm` object.
  """
  def extract(graph) do
    primitive_types =
      Paradigm.Graph.get_all_nodes_of_class(graph, "primitive_type")
      |> Enum.map(fn id -> {id, Paradigm.Graph.get_node(graph, id)} end)
      |> Enum.map(fn {id, node} ->
        {id,
         %Paradigm.PrimitiveType{
           name: node.data["name"]
         }}
      end)
      |> Map.new()

    packages =
      Paradigm.Graph.get_all_nodes_of_class(graph, "package")
      |> Enum.map(fn id -> {id, Paradigm.Graph.get_node(graph, id)} end)
      |> Enum.map(fn {id, node} ->
        {id,
         %Paradigm.Package{
           name: node.data["name"],
           uri: node.data["uri"],
           nested_packages: extract_ref_ids(node.data["nested_packages"]),
           owned_types: extract_ref_ids(node.data["owned_types"])
         }}
      end)
      |> Map.new()

    classes =
      Paradigm.Graph.get_all_nodes_of_class(graph, "class")
      |> Enum.map(fn id -> {id, Paradigm.Graph.get_node(graph, id)} end)
      |> Enum.map(fn {id, node} ->
        {id,
         %Paradigm.Class{
           name: node.data["name"],
           is_abstract: node.data["is_abstract"],
           owned_attributes: extract_ref_ids(node.data["owned_attributes"]),
           super_classes: extract_ref_ids(node.data["super_classes"])
         }}
      end)
      |> Map.new()

    enumerations =
      Paradigm.Graph.get_all_nodes_of_class(graph, "enumeration")
      |> Enum.map(fn id -> {id, Paradigm.Graph.get_node(graph, id)} end)
      |> Enum.map(fn {id, node} ->
        {id,
         %Paradigm.Enumeration{
           name: node.data["name"],
           literals: node.data["literals"]
         }}
      end)
      |> Map.new()

    properties =
      Paradigm.Graph.get_all_nodes_of_class(graph, "property")
      |> Enum.map(fn id -> {id, Paradigm.Graph.get_node(graph, id)} end)
      |> Enum.map(fn {id, node} ->
        {id,
         %Paradigm.Property{
           name: node.data["name"],
           is_ordered: node.data["is_ordered"],
           type: extract_ref_id(node.data["type"]),
           is_composite: node.data["is_composite"],
           lower_bound: node.data["lower_bound"],
           upper_bound: node.data["upper_bound"],
           default_value: node.data["default_value"]
         }}
      end)
      |> Map.new()

    %Paradigm{
      name: graph.metadata[:name],
      description: graph.metadata[:description],
      primitive_types: primitive_types,
      packages: packages,
      classes: classes,
      enumerations: enumerations,
      properties: properties
    }
  end

  defp extract_ref_ids(nil), do: []

  defp extract_ref_ids(refs) when is_list(refs) do
    Enum.map(refs, fn
      %Ref{id: id} -> id
      id when is_binary(id) -> id
    end)
  end

  defp extract_ref_id(nil), do: nil
  defp extract_ref_id(%Ref{id: id}), do: id
  defp extract_ref_id(id) when is_binary(id), do: id
end
